pragma solidity ^0.5.0;

import "./interfaces/TubInterface.sol";
import "./interfaces/ExchangeInterface.sol";
import "./DS/DSMath.sol";
import "./SaverLogger.sol";

/// @title SaverProxy implements advanced dashboard features repay/boost
contract SaverProxy is DSMath {
    //KOVAN
    address public constant WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public constant DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public constant MKR_ADDRESS = 0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD;
    address public constant VOX_ADDRESS = 0xBb4339c0aB5B1d9f14Bd6e3426444A1e9d86A1d9;
    address public constant PETH_ADDRESS = 0xf4d791139cE033Ad35DB2B2201435fAd668B1b64;
    address public constant TUB_ADDRESS = 0xa71937147b55Deb8a530C7229C442Fd3F31b7db2;
    address public constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant LOGGER_ADDRESS = 0x32d0e18f988F952Eb3524aCE762042381a2c39E5;
    address public constant WALLET_ID = 0x54b44C6B18fc0b4A1010B21d524c338D1f8065F6;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    address public constant KYBER_WRAPPER = 0x5595930d576Aedf13945C83cE5aaD827529A1310;
    address public constant UNISWAP_WRAPPER = 0x5595930d576Aedf13945C83cE5aaD827529A1310;
    address public constant ETH2DAI_WRAPPER = 0x823cde416973a19f98Bb9C96d97F4FE6C9A7238B;

    /// @notice Withdraws Eth collateral, swaps Eth -> Dai with Kyber, and pays back the debt in Dai
    /// @dev If _buyMkr is false user needs to have MKR tokens and approve his DSProxy
    /// @param _cup Id of the CDP
    /// @param _amount Amount of Eth to sell
    /// @param _minPrice Minimum acaptable ETH/DAI price
    function repay(bytes32 _cup, uint _amount, uint _minPrice, uint _exchangeType) public {
        address exchangeWrapper;
        uint ethDaiPrice;

        (exchangeWrapper, ethDaiPrice) = getBestPrice(_amount, ETHER_ADDRESS, DAI_ADDRESS, _exchangeType);

        require(ethDaiPrice > _minPrice, "Slppage hit");

        TubInterface tub = TubInterface(TUB_ADDRESS);

        approveTub(DAI_ADDRESS);
        approveTub(MKR_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(WETH_ADDRESS);

        uint startingRatio = getRatio(tub, _cup);

        if (_amount > maxFreeCollateral(tub, _cup)) {
            _amount = maxFreeCollateral(tub, _cup);
        }

        withdrawEth(tub, _cup, _amount);

        uint daiAmount = wmul(_amount, ethDaiPrice);
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
                            value(_amount)(_amount, DAI_ADDRESS, uint(-1));

         // Take a fee from the user in dai
         daiAmount = sub(daiAmount, takeFee(daiAmount));
        
        if (daiAmount > cdpWholeDebt) {
            tub.wipe(_cup, cdpWholeDebt);
            ERC20(DAI_ADDRESS).transfer(msg.sender, sub(daiAmount, cdpWholeDebt));
        } else {
            tub.wipe(_cup, daiAmount);
            // require(getRatio(tub, _cup) > startingRatio, "ratio must be better off at the end");
        }

        SaverLogger(LOGGER_ADDRESS).LogRepay(uint(_cup), msg.sender, _amount, daiAmount);
    }

    /// @notice Boost will draw Dai, swap Dai -> Eth on kyber, and add that Eth to the CDP
    /// @dev Amount must be less then the max. amount available Dai to generate
    /// @param _cup Id of the CDP
    /// @param _amount Amount of Dai to sell
    /// @param _minPrice Minimum acaptable ETH/DAI price
    function boost(bytes32 _cup, uint _amount, uint _minPrice, uint _exchangeType) public {
        address exchangeWrapper;
        uint daiEthPrice;

        (exchangeWrapper, daiEthPrice) = getBestPrice(_amount, DAI_ADDRESS, ETHER_ADDRESS, _exchangeType);

        require(wdiv(1000000000000000000, daiEthPrice) < _minPrice, "Slippage hit");

        TubInterface tub = TubInterface(TUB_ADDRESS);

        approveTub(WETH_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(DAI_ADDRESS);
        
        uint maxAmount = maxFreeDai(tub, _cup);

        if (_amount > maxAmount) {
            _amount = maxAmount;
        }

        uint startingCollateral = tub.ink(_cup);
        
        tub.draw(_cup, _amount);

        // Take a fee from the user in dai
        _amount = sub(_amount, takeFee(_amount));
        
        uint ethAmount = swapDaiAndLockEth(tub, _cup, _amount, exchangeWrapper);

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

        ERC20(DAI_ADDRESS).transfer(_exchangeWrapper, _daiAmount);

        uint ethAmount = ExchangeInterface(_exchangeWrapper).swapTokenToEther(DAI_ADDRESS, _daiAmount, uint(-1));
        
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
        ERC20(DAI_ADDRESS).transfer(WALLET_ID, feeAmount);
    }

    /// @notice Returns the best estimated price from 2 exchanges
    /// @param _amount Amount of source tokens you want to exchange
    /// @param _srcToken Address of the source token
    /// @param _destToken Address of the destination token
    /// @return (address, uint) The address of the best exchange and the exchange price
    function getBestPrice(uint _amount, address _srcToken, address _destToken, uint _exchangeType) public returns (address, uint) {
        uint expectedRateKyber = 0;
        uint expectedRateUniswap = 0;
        uint expectedRateEth2Dai = 0;

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

        if ((expectedRateEth2Dai >= expectedRateKyber) && (expectedRateEth2Dai >= expectedRateUniswap)) {
            return (ETH2DAI_WRAPPER, expectedRateEth2Dai);
        }

        if ((expectedRateKyber >= expectedRateUniswap) && (expectedRateKyber >= expectedRateEth2Dai)) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if ((expectedRateUniswap >= expectedRateKyber) && (expectedRateUniswap >= expectedRateEth2Dai)) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }
    }

    /// @notice Returns expected rate for Eth -> Dai conversion
    /// @param _amount Amount of Ether
    function estimatedDaiPrice(uint _amount) internal returns (uint expectedRate) {
        (expectedRate, ) = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(ETHER_ADDRESS, DAI_ADDRESS, _amount);
    }

    /// @notice Returns expected rate for Dai -> Eth conversion
    /// @param _amount Amount of Dai
    function estimatedEthPrice(uint _amount) internal returns (uint expectedRate) {
        (expectedRate, ) = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(DAI_ADDRESS, ETHER_ADDRESS, _amount);
    }

    /// @notice Returns expected rate for Eth -> Mkr conversion
    /// @param _amount Amount of Ether
    function estimatedMkrPrice(uint _amount) internal returns (uint expectedRate) {
        (expectedRate, ) = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(ETHER_ADDRESS, MKR_ADDRESS, _amount);
    }

    /// @notice Returns current Dai debt of the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function getDebt(TubInterface _tub, bytes32 _cup) internal returns (uint debt) {
        ( , , debt, ) = _tub.cups(_cup);
    }
}
