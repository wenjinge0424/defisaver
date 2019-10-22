pragma solidity ^0.5.0;

import "../interfaces/ExchangeInterface.sol";
import "../DS/DSMath.sol";
import "../constants/ConstantAddresses.sol";
import "../Discount.sol";

contract SaverExchange is DSMath, ConstantAddresses {

    uint public constant SERVICE_FEE = 800; // 0.125% Fee

    function swapTokenToToken(address _src, address _dest, uint _amount, uint _minPrice, uint _exchangeType) public payable {
        if (_src == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount);
            // return user if he sent too much
            msg.sender.transfer(sub(msg.value, _amount));
        } else {
            require(ERC20(_src).transferFrom(msg.sender, address(this), _amount));
        }

        uint fee = takeFee(_amount, _src);
        _amount = sub(_amount, fee);

        address wrapper;
        uint price;
        (wrapper, price) = getBestPrice(_amount, _src, _dest, _exchangeType);

        require(price > _minPrice, "Slippage hit");

        uint tokensReturned;
        if (_src == KYBER_ETH_ADDRESS) {
            (tokensReturned,) = ExchangeInterface(wrapper).swapEtherToToken.value(_amount)(_amount, _dest, uint(-1));
        } else {
            ERC20(_src).transfer(wrapper, _amount);

            if (_dest == KYBER_ETH_ADDRESS) {
                tokensReturned = ExchangeInterface(wrapper).swapTokenToEther(_src, _amount, uint(-1));
            } else {
                tokensReturned = ExchangeInterface(wrapper).swapTokenToToken(_src, _dest, _amount);
            }
        }

        if (_dest == KYBER_ETH_ADDRESS) {
            msg.sender.transfer(tokensReturned);
        } else {
            ERC20(_dest).transfer(msg.sender, tokensReturned);
        }
    }


    // legacy ------------------------------------------------------------

    function swapDaiToEth(uint _amount, uint _minPrice, uint _exchangeType) public {
        require(ERC20(MAKER_DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount));

        uint fee = takeFee(_amount, MAKER_DAI_ADDRESS);
        _amount = sub(_amount, fee);

        address exchangeWrapper;
        uint daiEthPrice;
        (exchangeWrapper, daiEthPrice) = getBestPrice(_amount, MAKER_DAI_ADDRESS, KYBER_ETH_ADDRESS, _exchangeType);

        require(daiEthPrice > _minPrice, "Slippage hit");

        ERC20(MAKER_DAI_ADDRESS).transfer(exchangeWrapper, _amount);
        ExchangeInterface(exchangeWrapper).swapTokenToEther(MAKER_DAI_ADDRESS, _amount, uint(-1));

        uint daiBalance = ERC20(MAKER_DAI_ADDRESS).balanceOf(address(this));
        if (daiBalance > 0) {
            ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, daiBalance);
        }

        msg.sender.transfer(address(this).balance);
    }

    function swapEthToDai(uint _amount, uint _minPrice, uint _exchangeType) public payable {
        require(msg.value >= _amount);

        address exchangeWrapper;
        uint ethDaiPrice;
        (exchangeWrapper, ethDaiPrice) = getBestPrice(_amount, KYBER_ETH_ADDRESS, MAKER_DAI_ADDRESS, _exchangeType);

        require(ethDaiPrice > _minPrice, "Slippage hit");

        uint ethReturned;
        uint daiReturned;
        (daiReturned, ethReturned) = ExchangeInterface(exchangeWrapper).swapEtherToToken.value(_amount)(_amount, MAKER_DAI_ADDRESS, uint(-1));

        uint fee = takeFee(daiReturned, MAKER_DAI_ADDRESS);
        daiReturned = sub(daiReturned, fee);

        ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, daiReturned);

        if (ethReturned > 0) {
            msg.sender.transfer(ethReturned);
        }
    }


    /// @notice Returns the best estimated price from 2 exchanges
    /// @param _amount Amount of source tokens you want to exchange
    /// @param _srcToken Address of the source token
    /// @param _destToken Address of the destination token
    /// @return (address, uint) The address of the best exchange and the exchange price
    function getBestPrice(uint _amount, address _srcToken, address _destToken, uint _exchangeType) public returns (address, uint) {
        uint expectedRateKyber;
        uint expectedRateUniswap;
        uint expectedRateOasis;


        if (_exchangeType == 1) {
            return (OASIS_WRAPPER, getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount));
        }

        if (_exchangeType == 2) {
            return (KYBER_WRAPPER, getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount));
        }

        if (_exchangeType == 3) {
            expectedRateUniswap = getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount);
            expectedRateUniswap = expectedRateUniswap * (10 ** (18 - getDecimals(_destToken)));
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }

        expectedRateKyber = getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount);
        expectedRateUniswap = getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount);
        expectedRateUniswap = expectedRateUniswap * (10 ** (18 - getDecimals(_destToken)));
        expectedRateOasis = getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount);

        if ((expectedRateKyber >= expectedRateUniswap) && (expectedRateKyber >= expectedRateOasis)) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if ((expectedRateOasis >= expectedRateKyber) && (expectedRateOasis >= expectedRateUniswap)) {
            return (ETH2DAI_WRAPPER, expectedRateOasis);
        }

        if ((expectedRateUniswap >= expectedRateKyber) && (expectedRateUniswap >= expectedRateOasis)) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }
    }

    function getExpectedRate(address _wrapper, address _srcToken, address _destToken, uint _amount) public returns(uint) {
        bool success;
        bytes memory result;

        (success, result) = _wrapper.call(abi.encodeWithSignature("getExpectedRate(address,address,uint256)", _srcToken, _destToken, _amount));

        if (success) {
            return sliceUint(result, 0);
        } else {
            return 0;
        }
    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @return feeAmount Amount in Dai owner earned on the fee
    function takeFee(uint _amount, address _token) internal returns (uint feeAmount) {
        uint fee = SERVICE_FEE;

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(msg.sender)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(msg.sender);
        }

        if (fee == 0) {
            feeAmount = 0;
        } else {
            feeAmount = _amount / SERVICE_FEE;
            if (_token == KYBER_ETH_ADDRESS) {
                WALLET_ID.transfer(feeAmount);
            } else {
                ERC20(_token).transfer(WALLET_ID, feeAmount);
            }
        }
    }


    function getDecimals(address _token) internal view returns(uint) {
        // DGD
        if (_token == address(0xE0B7927c4aF23765Cb51314A0E0521A9645F0E2A)) {
            return 9;
        }
        // USDC
        if (_token == address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) {
            return 6;
        }
        // WBTC
        if (_token == address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)) {
            return 8;
        }

        return 18;
    }

    function sliceUint(bytes memory bs, uint start) internal pure returns (uint) {
        require(bs.length >= start + 32, "slicing out of range");

        uint x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }

    // receive eth from wrappers
    function() external payable {}
}
