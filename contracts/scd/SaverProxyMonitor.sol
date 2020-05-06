pragma solidity ^0.6.0;

import "../interfaces/TubInterface.sol";
import "../interfaces/ExchangeInterface.sol";
import "../DS/DSMath.sol";
import "../loggers/SaverLogger.sol";
import "../constants/ConstantAddresses.sol";


/// @title SaverProxy implements advanced dashboard features repay/boost
contract SaverProxyMonitor is DSMath, ConstantAddresses {
    uint256 public constant SERVICE_FEE = 400; // 0.25% Fee

    /// @notice Withdraws Eth collateral, swaps Eth -> Dai with Kyber, and pays back the debt in Dai
    /// @dev If _buyMkr is false user needs to have MKR tokens and approve his DSProxy
    /// @param _cup Id of the CDP
    /// @param _gasCost taking the amount needed for tx gas cost
    function repay(bytes32 _cup, uint256 _amount, uint256 _gasCost) public {
        address exchangeWrapper;
        uint256 ethDaiPrice;

        (exchangeWrapper, ethDaiPrice) = getBestPrice(
            _amount,
            KYBER_ETH_ADDRESS,
            MAKER_DAI_ADDRESS,
            0
        );

        TubInterface tub = TubInterface(TUB_ADDRESS);

        approveTub(MAKER_DAI_ADDRESS);
        approveTub(MKR_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(WETH_ADDRESS);

        address owner = getOwner(tub, _cup);

        uint256 startingRatio = getRatio(tub, _cup);

        if (_amount > maxFreeCollateral(tub, _cup)) {
            _amount = maxFreeCollateral(tub, _cup);
        }

        withdrawEth(tub, _cup, _amount);

        uint256 daiAmount = wmul(_amount, ethDaiPrice);
        uint256 cdpWholeDebt = getDebt(tub, _cup);

        uint256 mkrAmount = stabilityFeeInMkr(tub, _cup, sub(daiAmount, daiAmount / SERVICE_FEE));

        if (daiAmount > cdpWholeDebt) {
            mkrAmount = stabilityFeeInMkr(tub, _cup, cdpWholeDebt);
        }

        uint256 ethFee = wdiv(mkrAmount, estimatedMkrPrice(_amount));

        uint256 change;
        (, change) = ExchangeInterface(KYBER_WRAPPER).swapEtherToToken{value: ethFee}(
            ethFee,
            MKR_ADDRESS,
            mkrAmount
        );

        _amount = sub(_amount, sub(ethFee, change));

        (daiAmount, ) = ExchangeInterface(exchangeWrapper).swapEtherToToken{value: _amount}(
            _amount,
            MAKER_DAI_ADDRESS,
            uint256(-1)
        );

        // Take a fee from the user in dai
        daiAmount = sub(daiAmount, takeFee(daiAmount, _gasCost, ethDaiPrice));

        if (daiAmount > cdpWholeDebt) {
            tub.wipe(_cup, cdpWholeDebt);
            // FIX
            ERC20(MAKER_DAI_ADDRESS).transfer(owner, sub(daiAmount, cdpWholeDebt));
        } else {
            tub.wipe(_cup, daiAmount);
            require(getRatio(tub, _cup) > startingRatio, "ratio must be better off at the end");
        }

        SaverLogger(LOGGER_ADDRESS).LogRepay(uint256(_cup), owner, _amount, daiAmount);
    }

    /// @notice Boost will draw Dai, swap Dai -> Eth on kyber, and add that Eth to the CDP
    /// @dev Amount must be less then the max. amount available Dai to generate
    /// @param _cup Id of the CDP
    /// @param _gasCost taking the amount needed for tx gas cost
    function boost(bytes32 _cup, uint256 _amount, uint256 _gasCost) public {
        address exchangeWrapper;
        uint256 daiEthPrice;

        (exchangeWrapper, daiEthPrice) = getBestPrice(
            _amount,
            MAKER_DAI_ADDRESS,
            KYBER_ETH_ADDRESS,
            0
        );

        uint256 ethDaiPrice = wdiv(1000000000000000000, daiEthPrice);

        TubInterface tub = TubInterface(TUB_ADDRESS);

        approveTub(WETH_ADDRESS);
        approveTub(PETH_ADDRESS);
        approveTub(MAKER_DAI_ADDRESS);

        uint256 maxAmount = maxFreeDai(tub, _cup);

        if (_amount > maxAmount) {
            _amount = maxAmount;
        }

        uint256 startingCollateral = tub.ink(_cup);

        tub.draw(_cup, _amount);

        // Take a fee from the user in dai
        _amount = sub(_amount, takeFee(_amount, _gasCost, ethDaiPrice));

        uint256 ethAmount = swapDaiAndLockEth(tub, _cup, _amount, exchangeWrapper);

        require(
            tub.ink(_cup) > startingCollateral,
            "collateral must be bigger than starting point"
        );

        SaverLogger(LOGGER_ADDRESS).LogBoost(uint256(_cup), msg.sender, _amount, ethAmount);
    }

    /// @notice Max. amount of collateral available to withdraw
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function maxFreeCollateral(TubInterface _tub, bytes32 _cup) public returns (uint256) {
        return
            sub(
                _tub.ink(_cup),
                wdiv(
                    wmul(
                        wmul(_tub.tab(_cup), rmul(_tub.mat(), WAD)),
                        VoxInterface(VOX_ADDRESS).par()
                    ),
                    _tub.tag()
                )
            ) -
            1;
    }

    /// @notice Max. amount of Dai available to generate
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function maxFreeDai(TubInterface _tub, bytes32 _cup) public returns (uint256) {
        return
            sub(wdiv(rmul(_tub.ink(_cup), _tub.tag()), rmul(_tub.mat(), WAD)), _tub.tab(_cup)) - 1;
    }

    /// @notice Stability fee amount in Mkr
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    /// @param _daiRepay Amount of dai we are repaying
    function stabilityFeeInMkr(TubInterface _tub, bytes32 _cup, uint256 _daiRepay)
        public
        returns (uint256)
    {
        bytes32 mkrPrice;
        bool ok;

        uint256 feeInDai = rmul(_daiRepay, rdiv(_tub.rap(_cup), _tub.tab(_cup)));

        (mkrPrice, ok) = _tub.pep().peek();

        return wdiv(feeInDai, uint256(mkrPrice));
    }

    /// @notice Helper function which swaps Dai for Eth and adds the collateral to the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    /// @param _daiAmount Amount of Dai to swap for Eth
    function swapDaiAndLockEth(
        TubInterface _tub,
        bytes32 _cup,
        uint256 _daiAmount,
        address _exchangeWrapper
    ) internal returns (uint256) {
        ERC20(MAKER_DAI_ADDRESS).transfer(_exchangeWrapper, _daiAmount);

        uint256 ethAmount = ExchangeInterface(_exchangeWrapper).swapTokenToEther(
            MAKER_DAI_ADDRESS,
            _daiAmount,
            uint256(-1)
        );

        _tub.gem().deposit{value: ethAmount}();

        uint256 ink = sub(rdiv(ethAmount, _tub.per()), 1);

        _tub.join(ink);

        _tub.lock(_cup, ink);

        return ethAmount;
    }

    /// @notice Approve a token if it's not already approved
    /// @param _tokenAddress Address of the ERC20 token we want to approve
    function approveTub(address _tokenAddress) internal {
        if (ERC20(_tokenAddress).allowance(msg.sender, _tokenAddress) < (uint256(-1) / 2)) {
            ERC20(_tokenAddress).approve(TUB_ADDRESS, uint256(-1));
        }
    }

    /// @notice Returns the current collaterlization ratio for the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function getRatio(TubInterface _tub, bytes32 _cup) internal returns (uint256) {
        return (wdiv(rmul(rmul(_tub.ink(_cup), _tub.tag()), WAD), _tub.tab(_cup)));
    }

    /// @notice Helper function which withdraws collateral from CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    /// @param _ethAmount Amount of Eth to withdraw
    function withdrawEth(TubInterface _tub, bytes32 _cup, uint256 _ethAmount) internal {
        uint256 ink = rdiv(_ethAmount, _tub.per());
        _tub.free(_cup, ink);

        _tub.exit(ink);
        _tub.gem().withdraw(_ethAmount);
    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @param _gasFee Aditional fee for gas payment
    /// @param _price Price of Eth in Dai so we can take the fee in Dai
    /// @return feeAmount Amount in Dai owner earned on the fee
    function takeFee(uint256 _amount, uint256 _gasFee, uint256 _price)
        internal
        returns (uint256 feeAmount)
    {
        uint256 gasFeeDai = wmul(_gasFee, _price); // The gas price of the tx in Dai

        feeAmount = add((_amount / SERVICE_FEE), gasFeeDai);

        // if fee + gas cost is more than 20% of amount, lock it to 20%
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        ERC20(MAKER_DAI_ADDRESS).transfer(WALLET_ID, feeAmount);
    }

    /// @notice Returns the best estimated price from 2 exchanges
    /// @param _amount Amount of source tokens you want to exchange
    /// @param _srcToken Address of the source token
    /// @param _destToken Address of the destination token
    /// @return (address, uint) The address of the best exchange and the exchange price
    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        uint256 _exchangeType
    ) public view returns (address, uint256) {
        uint256 expectedRateKyber = 0;
        uint256 expectedRateUniswap = 0;
        uint256 expectedRateEth2Dai = 0;

        expectedRateKyber = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(
            _srcToken,
            _destToken,
            _amount
        );
        expectedRateUniswap = ExchangeInterface(UNISWAP_WRAPPER).getExpectedRate(
            _srcToken,
            _destToken,
            _amount
        );
        expectedRateEth2Dai = ExchangeInterface(ETH2DAI_WRAPPER).getExpectedRate(
            _srcToken,
            _destToken,
            _amount
        );

        if (_exchangeType == 1) {
            return (ETH2DAI_WRAPPER, expectedRateEth2Dai);
        }

        if (_exchangeType == 2) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if (_exchangeType == 3) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }

        if (
            (expectedRateEth2Dai >= expectedRateKyber) &&
            (expectedRateEth2Dai >= expectedRateUniswap)
        ) {
            return (ETH2DAI_WRAPPER, expectedRateEth2Dai);
        }

        if (
            (expectedRateKyber >= expectedRateUniswap) && (expectedRateKyber >= expectedRateEth2Dai)
        ) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if (
            (expectedRateUniswap >= expectedRateKyber) &&
            (expectedRateUniswap >= expectedRateEth2Dai)
        ) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }
    }

    /// @notice Returns expected rate for Eth -> Dai conversion
    /// @param _amount Amount of Ether
    function estimatedDaiPrice(uint256 _amount) internal view returns (uint256 expectedRate) {
        expectedRate = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(
            KYBER_ETH_ADDRESS,
            MAKER_DAI_ADDRESS,
            _amount
        );
    }

    /// @notice Returns expected rate for Dai -> Eth conversion
    /// @param _amount Amount of Dai
    function estimatedEthPrice(uint256 _amount) internal view returns (uint256 expectedRate) {
        expectedRate = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(
            MAKER_DAI_ADDRESS,
            KYBER_ETH_ADDRESS,
            _amount
        );
    }

    /// @notice Returns expected rate for Eth -> Mkr conversion
    /// @param _amount Amount of Ether
    function estimatedMkrPrice(uint256 _amount) internal view returns (uint256 expectedRate) {
        expectedRate = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(
            KYBER_ETH_ADDRESS,
            MKR_ADDRESS,
            _amount
        );
    }

    /// @notice Returns current Dai debt of the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function getDebt(TubInterface _tub, bytes32 _cup) internal returns (uint256 debt) {
        (, , debt, ) = _tub.cups(_cup);
    }

    /// @notice Returns the owner of the CDP
    /// @param _tub Tub interface
    /// @param _cup Id of the CDP
    function getOwner(TubInterface _tub, bytes32 _cup) internal returns (address owner) {
        (owner, , , ) = _tub.cups(_cup);
    }
}
