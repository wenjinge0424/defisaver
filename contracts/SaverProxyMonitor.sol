pragma solidity ^0.5.0;

import "./interfaces/TubInterface.sol";
import "./interfaces/ExchangeInterface.sol";
import "./DS/DSMath.sol";
import "./SaverLogger.sol";
import "./constants/ConstantAddresses.sol";

/// @title SaverProxy implements advanced dashboard features repay/boost
contract SaverProxy is DSMath, ConstantAddresses {

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    /// @notice Withdraws Eth collateral, swaps Eth -> Dai with Kyber, and pays back the debt in Dai
    /// @dev If _buyMkr is false user needs to have MKR tokens and approve his DSProxy
    /// @param _cup Id of the CDP
    /// @param _amount Amount of Eth to sell
    /// @param _minPrice Minimum acaptable ETH/DAI price
    function repay(bytes32 _cup, uint _amount, uint _minPrice, uint _borrowedAmount) public {
        address exchangeWrapper;
        uint ethDaiPrice;

        (exchangeWrapper, ethDaiPrice) = getBestPrice(_amount, KYBER_ETH_ADDRESS, MAKER_DAI_ADDRESS, 0);

        require(ethDaiPrice > _minPrice, "Slppage hit");

        TubInterface tub = TubInterface(TUB_ADDRESS);

        approveTub(MAKER_DAI_ADDRESS);
        approveTub(MKR_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(WETH_ADDRESS);

        uint startingRatio = getRatio(tub, _cup);

        if (_amount > maxFreeCollateral(tub, _cup)) {
            _amount = maxFreeCollateral(tub, _cup);
        }

        withdrawEth(tub, _cup, _amount);

        uint daiAmount = add(wmul(_amount, ethDaiPrice), _borrowedAmount);
        uint cdpWholeDebt = getDebt(tub, _cup);

        uint mkrAmount = stabilityFeeInMkr(tub, _cup, sub(daiAmount, daiAmount / SERVICE_FEE));

        if (daiAmount > cdpWholeDebt) {
            mkrAmount = stabilityFeeInMkr(tub, _cup, cdpWholeDebt);
        }

        uint ethFee = wdiv(mkrAmount, estimatedMkrPrice(_amount));

        uint change;
        (, change) = ExchangeInterface(KYBER_WRAPPER).swapEtherToToken.
                        value(ethFee)(ethFee, MKR_ADDRESS, mkrAmount);


        _amount = sub(_amount, sub(ethFee, change));

        (daiAmount, ) = ExchangeInterface(exchangeWrapper).swapEtherToToken.
                            value(_amount)(_amount, MAKER_DAI_ADDRESS, uint(-1));

        daiAmount = add(daiAmount, _borrowedAmount);

        // Take a fee from the user in dai
        daiAmount = sub(daiAmount, takeFee(daiAmount));

        if (daiAmount > cdpWholeDebt) {
            tub.wipe(_cup, cdpWholeDebt);
            ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, sub(daiAmount, cdpWholeDebt));
        } else {
            tub.wipe(_cup, daiAmount);
            // require(getRatio(tub, _cup) > startingRatio, "ratio must be better off at the end");
        }

        if (_borrowedAmount > 0) {
            tub.draw(_cup, _borrowedAmount);
            ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, _borrowedAmount);
        }

        SaverLogger(LOGGER_ADDRESS).LogRepay(uint(_cup), msg.sender, _amount, daiAmount);
    }

    /// @notice Boost will draw Dai, swap Dai -> Eth on kyber, and add that Eth to the CDP
    /// @dev Amount must be less then the max. amount available Dai to generate
    /// @param _cup Id of the CDP
    /// @param _amount Amount of Dai to sell
    /// @param _minPrice Minimum acaptable ETH/DAI price
    function boost(bytes32 _cup, uint _amount, uint _minPrice, uint _borrowedAmount) public {
        address exchangeWrapper;
        uint daiEthPrice;

        (exchangeWrapper, daiEthPrice) = getBestPrice(_amount, MAKER_DAI_ADDRESS, KYBER_ETH_ADDRESS, 0);

        require(wdiv(1000000000000000000, daiEthPrice) < _minPrice, "Slippage hit");

        TubInterface tub = TubInterface(TUB_ADDRESS);

        approveTub(WETH_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(MAKER_DAI_ADDRESS);

        uint maxAmount = maxFreeDai(tub, _cup);

        if (_amount > maxAmount) {
            _amount = maxAmount;
        }

        uint startingCollateral = tub.ink(_cup);

        tub.draw(_cup, _amount);

        _amount = add(_amount, _borrowedAmount);

        // Take a fee from the user in dai
        _amount = sub(_amount, takeFee(_amount));

        uint ethAmount = swapDaiAndLockEth(tub, _cup, _amount, exchangeWrapper);

        if (_borrowedAmount > 0) {
            tub.draw(_cup, _borrowedAmount);
            ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, _borrowedAmount);
        }

        // require(tub.ink(_cup) > startingCollateral, "collateral must be bigger than starting point");

        SaverLogger(LOGGER_ADDRESS).LogBoost(uint(_cup), msg.sender, _amount, ethAmount);
    }

    /// @notice Max. amount of collateral available to withdraw
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function maxFreeCollateral(TubInterface _tub, bytes32 _cup) public returns (uint) {
        return sub(_tub.ink(_cup), wdiv(wmul(wmul(_tub.tab(_cup), rmul(_tub.mat(), WAD)),
                VoxInterface(VOX_ADDRESS).par()), _tub.tag())) - 1;
    }

    /// @notice Max. amount of Dai available to generate
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function maxFreeDai(TubInterface _tub, bytes32 _cup) public returns (uint) {
        return sub(wdiv(rmul(_tub.ink(_cup), _tub.tag()), rmul(_tub.mat(), WAD)), _tub.tab(_cup)) - 1;
    }

    /// @notice Stability fee amount in Mkr
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    /// @param _daiRepay Amount of dai we are repaying
    function stabilityFeeInMkr(TubInterface _tub, bytes32 _cup, uint _daiRepay) public returns (uint) {
        bytes32 mkrPrice;
        bool ok;

        uint feeInDai = rmul(_daiRepay, rdiv(_tub.rap(_cup), _tub.tab(_cup)));

        (mkrPrice, ok) = _tub.pep().peek();

        return wdiv(feeInDai, uint(mkrPrice));
    }

    /// @notice Helper function which swaps Dai for Eth and adds the collateral to the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    /// @param _daiAmount Amount of Dai to swap for Eth
    function swapDaiAndLockEth(TubInterface _tub, bytes32 _cup, uint _daiAmount, address _exchangeWrapper) internal returns(uint) {

        ERC20(MAKER_DAI_ADDRESS).transfer(_exchangeWrapper, _daiAmount);

        uint ethAmount = ExchangeInterface(_exchangeWrapper).swapTokenToEther(MAKER_DAI_ADDRESS, _daiAmount, uint(-1));

        _tub.gem().deposit.value(ethAmount)();

        uint ink = sub(rdiv(ethAmount, _tub.per()), 1);

        _tub.join(ink);

        _tub.lock(_cup, ink);

        return ethAmount;
    }

    /// @notice Approve a token if it's not already approved
    /// @param _tokenAddress Address of the ERC20 token we want to approve
    function approveTub(address _tokenAddress) internal {
        if (ERC20(_tokenAddress).allowance(msg.sender, _tokenAddress) < (uint(-1) / 2)) {
            ERC20(_tokenAddress).approve(TUB_ADDRESS, uint(-1));
        }
    }

    /// @notice Returns the current collaterlization ratio for the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function getRatio(TubInterface _tub, bytes32 _cup) internal returns(uint) {
        return (wdiv(rmul(rmul(_tub.ink(_cup), _tub.tag()), WAD), _tub.tab(_cup)));
    }

    /// @notice Helper function which withdraws collateral from CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    /// @param _ethAmount Amount of Eth to withdraw
    function withdrawEth(TubInterface _tub, bytes32 _cup, uint _ethAmount) internal {
        uint ink = rdiv(_ethAmount, _tub.per());
        _tub.free(_cup, ink);

        _tub.exit(ink);
        _tub.gem().withdraw(_ethAmount);
    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @return feeAmount Amount in Dai owner earned on the fee
    function takeFee(uint _amount) internal returns (uint feeAmount) {
        feeAmount = _amount / SERVICE_FEE;
        ERC20(MAKER_DAI_ADDRESS).transfer(WALLET_ID, feeAmount);
    }

    /// @notice Returns the best estimated price from 2 exchanges
    /// @param _amount Amount of source tokens you want to exchange
    /// @param _srcToken Address of the source token
    /// @param _destToken Address of the destination token
    /// @return (address, uint) The address of the best exchange and the exchange price
    function getBestPrice(uint _amount, address _srcToken, address _destToken, uint _exchangeType) internal returns (address, uint) {
        uint expectedRateKyber;
        uint expectedRateUniswap;
        uint expectedRateEth2Dai;

        (expectedRateKyber, ) = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);
        (expectedRateUniswap, ) = ExchangeInterface(UNISWAP_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);
        // (expectedRateEth2Dai, ) = ExchangeInterface(ETH2DAI_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);

        if (_exchangeType == 1) {
            return (ETH2DAI_WRAPPER, expectedRateEth2Dai);
        }

        if (_exchangeType == 2) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if (_exchangeType == 3) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }

        if (expectedRateEth2Dai > expectedRateKyber && expectedRateEth2Dai > expectedRateUniswap) {
            return (ETH2DAI_WRAPPER, expectedRateEth2Dai);
        }

        if (expectedRateKyber > expectedRateUniswap && expectedRateKyber > expectedRateEth2Dai) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if (expectedRateUniswap > expectedRateKyber && expectedRateUniswap > expectedRateEth2Dai) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }
    }

    /// @notice Returns expected rate for Eth -> Dai conversion
    /// @param _amount Amount of Ether
    function estimatedDaiPrice(uint _amount) internal returns (uint expectedRate) {
        (expectedRate, ) = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(KYBER_ETH_ADDRESS, MAKER_DAI_ADDRESS, _amount);
    }

    /// @notice Returns expected rate for Dai -> Eth conversion
    /// @param _amount Amount of Dai
    function estimatedEthPrice(uint _amount) internal returns (uint expectedRate) {
        (expectedRate, ) = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(MAKER_DAI_ADDRESS, KYBER_ETH_ADDRESS, _amount);
    }

    /// @notice Returns expected rate for Eth -> Mkr conversion
    /// @param _amount Amount of Ether
    function estimatedMkrPrice(uint _amount) internal returns (uint expectedRate) {
        (expectedRate, ) = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(KYBER_ETH_ADDRESS, MKR_ADDRESS, _amount);
    }

    /// @notice Returns current Dai debt of the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function getDebt(TubInterface _tub, bytes32 _cup) internal returns (uint debt) {
        ( , , debt, ) = _tub.cups(_cup);
    }
}
