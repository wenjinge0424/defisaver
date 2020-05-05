pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ExchangeInterface.sol";
import "../interfaces/TokenInterface.sol";
import "../DS/DSMath.sol";
import "./SaverExchangeConstantAddresses.sol";
import "../mcd/Discount.sol";
import "../loggers/ExchangeLogger.sol";

contract SaverExchange is DSMath, SaverExchangeConstantAddresses {
    uint256 public constant SERVICE_FEE = 800; // 0.125% Fee

    // solhint-disable-next-line const-name-snakecase
    ExchangeLogger public constant logger = ExchangeLogger(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // first is empty to keep the legacy order in place
    enum ExchangeType { _, OASIS, KYBER, UNISWAP, ZEROX }

    struct ExchangeData {
        address srcAddr;
        address destAddr;
        uint amount;
        uint minPrice;
        ExchangeType exchangeType;
        address exchangeAddr;
        bytes callData;
        uint256 price0x;
    }

    function swap(ExchangeData memory exData) public payable {
        // transfer tokens from the user
        pullTokens(exData.srcAddr, exData.amount);

        // take fee
        uint dfsFee = takeFee(exData.amount, exData.srcAddr);
        exData.amount = sub(exData.amount, dfsFee);

        address wrapper;
        uint swapedTokens;
        bool success;

        // if 0x is selected try first the 0x order
        if (exData.exchangeType == ExchangeType.ZEROX) {
            approve0xProxy(exData.srcAddr, exData.amount);

            (success, swapedTokens, ) = takeOrder(
                exData.exchangeAddr,
                exData.srcAddr,
                exData.destAddr,
                exData.callData,
                address(this).balance,
                exData.amount
            );

            // either it reverts or order doesn't exist anymore, we reverts as it was explicitely asked for this exchange
            require(success && swapedTokens > 0, "0x transaction failed");

            wrapper = exData.exchangeAddr;
        }

        // check if we have already swapped with 0x, or tried swapping but failed
        if (swapedTokens == 0) {

            uint price;
            uint tokensLeft = exData.amount;

            (wrapper, price)
                = getBestPrice(exData.amount, exData.srcAddr, exData.destAddr, exData.exchangeType);

            require(price > exData.minPrice || exData.price0x > exData.minPrice, "Slippage hit");

            // if 0x has better prices use 0x
            if (exData.price0x >= price) {
                approve0xProxy(exData.srcAddr, exData.amount);

                (success, swapedTokens, ) = takeOrder(
                    exData.exchangeAddr,
                    exData.srcAddr,
                    exData.destAddr,
                    exData.callData,
                    address(this).balance,
                    exData.amount
                );
            }

            // 0x either had worse price or we tried and order fill failed, so call on chain swap
            if (tokensLeft > 0) {
                swapedTokens = saverSwap(exData, wrapper);
            }
        }

        // send back any leftover ether or tokens
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }

        if (getBalance(exData.srcAddr) > 0) {
            ERC20(exData.srcAddr).transfer(msg.sender, getBalance(exData.srcAddr));
        }

        if (getBalance(exData.destAddr) > 0) {
            ERC20(exData.destAddr).transfer(msg.sender, getBalance(exData.destAddr));
        }

        logger.emitSwap(exData.srcAddr, exData.destAddr, exData.amount, swapedTokens, wrapper);
    }

    // @notice Takes order from 0x and returns bool indicating if it is successful
    // @param _data Data to send with call
    // @param _value Value to send with call
    // @param _amount Amount being sold
    function takeOrder(
        address _exchangeAddr,
        address _srcAddr,
        address _destAddr,
        bytes memory _data,
        uint256 _value,
        uint256 _amount
    ) private returns (bool success, uint256, uint256) {

        // solhint-disable-next-line avoid-call-value
        (success, ) = _exchangeAddr.call.value(_value)(_data);

        uint256 tokensSwaped = 0;
        uint256 tokensLeft = _amount;

        if (success) {
            // check to see if any _src tokens are left over after exchange
            tokensLeft = getBalance(_srcAddr);

            // convert weth -> eth if needed
            if (_srcAddr == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(
                    TokenInterface(WETH_ADDRESS).balanceOf(address(this))
                );
            }

            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(_destAddr);
        }

        return (success, tokensSwaped, tokensLeft);
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
        ExchangeType _exchangeType
    ) public returns (address, uint256) {
        uint256 expectedRateKyber;
        uint256 expectedRateUniswap;
        uint256 expectedRateOasis;

        if (_exchangeType == ExchangeType.OASIS) {
            return (OASIS_WRAPPER, getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount));
        }

        if (_exchangeType == ExchangeType.KYBER) {
            return (KYBER_WRAPPER, getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount));
        }

        if (_exchangeType == ExchangeType.UNISWAP) {
            expectedRateUniswap = getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount);
            expectedRateUniswap = expectedRateUniswap * (10**(18 - getDecimals(_destToken)));
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }

        expectedRateKyber = getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount);
        expectedRateUniswap = getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount);
        expectedRateUniswap = expectedRateUniswap * (10**(18 - getDecimals(_destToken)));
        expectedRateOasis = getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount);
        expectedRateOasis = expectedRateOasis * (10**(18 - getDecimals(_destToken)));

        if (
            (expectedRateKyber >= expectedRateUniswap) && (expectedRateKyber >= expectedRateOasis)
        ) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if (
            (expectedRateOasis >= expectedRateKyber) && (expectedRateOasis >= expectedRateUniswap)
        ) {
            return (OASIS_WRAPPER, expectedRateOasis);
        }

        if (
            (expectedRateUniswap >= expectedRateKyber) && (expectedRateUniswap >= expectedRateOasis)
        ) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }
    }

    function getExpectedRate(
        address _wrapper,
        address _srcToken,
        address _destToken,
        uint256 _amount
    ) public returns (uint256) {
        bool success;
        bytes memory result;

        (success, result) = _wrapper.call(
            abi.encodeWithSignature(
                "getExpectedRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            )
        );

        if (success) {
            return sliceUint(result, 0);
        } else {
            return 0;
        }
    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @return feeAmount Amount in Dai owner earned on the fee
    function takeFee(uint256 _amount, address _token) internal returns (uint256 feeAmount) {
        uint256 fee = SERVICE_FEE;

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

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == DGD_ADDRESS) return 9;

        return ERC20(_token).decimals();
    }

    function saverSwap(ExchangeData memory exData, address _wrapper) internal returns (uint swapedTokens) {
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            (swapedTokens, ) = ExchangeInterface(_wrapper).swapEtherToToken.value(exData.amount)(
                exData.amount,
                exData.destAddr,
                uint256(-1)
            );
        } else {
            ERC20(exData.srcAddr).transfer(_wrapper, exData.amount);

            if (exData.destAddr == KYBER_ETH_ADDRESS) {
                swapedTokens = ExchangeInterface(_wrapper).swapTokenToEther(
                    exData.srcAddr,
                    exData.amount,
                    uint256(-1)
                );
            } else {
                swapedTokens = ExchangeInterface(_wrapper).swapTokenToToken(
                    exData.srcAddr,
                    exData.destAddr,
                    exData.amount
                );
            }
        }
    }

    function pullTokens(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount, "msg.value smaller than amount");
        } else {
            require(
                ERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount),
                "Not able to withdraw wanted amount"
            );
        }
    }

    function getBalance(address _tokenAddr) internal view returns (uint balance) {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_tokenAddr).balanceOf(address(this));
        }
    }

    function approve0xProxy(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != KYBER_ETH_ADDRESS) {
            ERC20(_tokenAddr).approve(address(ERC20_PROXY_0X), _amount);
        }
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }

    // receive eth from wrappers
    receive() external payable {}
}
