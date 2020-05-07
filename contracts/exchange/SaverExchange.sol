pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SaverExchangeHelper.sol";
import "../interfaces/ExchangeInterface.sol";
import "../interfaces/TokenInterface.sol";
import "../DS/DSMath.sol";
import "../loggers/ExchangeLogger.sol";

contract SaverExchange is SaverExchangeHelper, DSMath {
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

        // Perform the exchange
        (address wrapper, uint swapedTokens) = _swap(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr);

        // log the event
        logger.logSwap(exData.srcAddr, exData.destAddr, exData.amount, swapedTokens, wrapper);
    }

    function _swap(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;
        uint tokensLeft = exData.amount;

        // Transform Weth address to Eth address kyber uses
        exData.srcAddr = wethToKyberEth(exData.srcAddr);
        exData.destAddr = wethToKyberEth(exData.destAddr);

        // if 0x is selected try first the 0x order
        if (exData.exchangeType == ExchangeType.ZEROX) {
            approve0xProxy(exData.srcAddr, exData.amount);

            (success, swapedTokens, tokensLeft) = takeOrder(exData, address(this).balance);

            // either it reverts or order doesn't exist anymore, we reverts as it was explicitely asked for this exchange
            require(success && tokensLeft == 0, "0x transaction failed");

            wrapper = exData.exchangeAddr;
        }

        // check if we have already swapped with 0x, or tried swapping but failed
        if (swapedTokens == 0) {
            uint price;

            (wrapper, price)
                = getBestPrice(exData.amount, exData.srcAddr, exData.destAddr, exData.exchangeType);

            require(price > exData.minPrice || exData.price0x > exData.minPrice, "Slippage hit");

            // if 0x has better prices use 0x
            if (exData.price0x >= price) {
                approve0xProxy(exData.srcAddr, exData.amount);

                (success, swapedTokens, tokensLeft) = takeOrder(exData, address(this).balance);
            }

            // 0x either had worse price or we tried and order fill failed, so call on chain swap
            if (tokensLeft > 0) {
                swapedTokens = saverSwap(exData, wrapper);
            }
        }

        return (wrapper, swapedTokens);
    }

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _0xFee Ether fee needed for 0x order
    function takeOrder(
        ExchangeData memory _exData,
        uint256 _0xFee
    ) private returns (bool success, uint256, uint256) {

        // solhint-disable-next-line avoid-call-value
        (success, ) = _exData.exchangeAddr.call{value: _0xFee}(_exData.callData);

        uint256 tokensSwaped = 0;
        uint256 tokensLeft = _exData.amount;

        if (success) {
            // check to see if any _src tokens are left over after exchange
            tokensLeft = getBalance(_exData.srcAddr);

            // convert weth -> eth if needed
            if (_exData.srcAddr == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(
                    TokenInterface(WETH_ADDRESS).balanceOf(address(this))
                );
            }

            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(_exData.destAddr);
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

    function saverSwap(ExchangeData memory exData, address _wrapper) internal returns (uint swapedTokens) {
        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            (swapedTokens, ) = ExchangeInterface(_wrapper).swapEtherToToken{value: exData.amount}(
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

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
