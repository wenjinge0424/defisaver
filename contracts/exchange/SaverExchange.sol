pragma solidity ^0.5.0;

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

    function swapTokenToToken(
        address _src,
        address _dest,
        uint256 _amount,
        uint256 _minPrice,
        uint256 _exchangeType,
        address _exchangeAddress,
        bytes memory _callData,
        uint256 _0xPrice
    ) public payable {
        // use this to avoid stack too deep error
        address[3] memory orderAddresses = [_exchangeAddress, _src, _dest];

        if (orderAddresses[1] == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount, "msg.value smaller than amount");
        } else {
            require(
                ERC20(orderAddresses[1]).transferFrom(msg.sender, address(this), _amount),
                "Not able to withdraw wanted amount"
            );
        }

        uint256 fee = takeFee(_amount, orderAddresses[1]);
        _amount = sub(_amount, fee);

        // [tokensReturned, tokensLeft]
        uint256[2] memory tokens;
        address wrapper;
        uint256 price;
        bool success;

        // at the beggining tokensLeft equals _amount
        tokens[1] = _amount;

        if (_exchangeType == 4) {
            if (orderAddresses[1] != KYBER_ETH_ADDRESS) {
                ERC20(orderAddresses[1]).approve(address(ERC20_PROXY_0X), _amount);
            }

            (success, tokens[0], ) = takeOrder(
                orderAddresses,
                _callData,
                address(this).balance,
                _amount
            );
            // either it reverts or order doesn't exist anymore, we reverts as it was explicitely asked for this exchange
            require(success && tokens[0] > 0, "0x transaction failed");
            wrapper = address(_exchangeAddress);
        }

        if (tokens[0] == 0) {
            (wrapper, price) = getBestPrice(
                _amount,
                orderAddresses[1],
                orderAddresses[2],
                _exchangeType
            );

            require(price > _minPrice || _0xPrice > _minPrice, "Slippage hit");

            // handle 0x exchange, if equal price, try 0x to use less gas
            if (_0xPrice >= price) {
                if (orderAddresses[1] != KYBER_ETH_ADDRESS) {
                    ERC20(orderAddresses[1]).approve(address(ERC20_PROXY_0X), _amount);
                }
                (success, tokens[0], tokens[1]) = takeOrder(
                    orderAddresses,
                    _callData,
                    address(this).balance,
                    _amount
                );
                // either it reverts or order doesn't exist anymore
                if (success && tokens[0] > 0) {
                    wrapper = address(_exchangeAddress);
                    logger.emitSwap(orderAddresses[1], orderAddresses[2], _amount, tokens[0], wrapper);
                }
            }

            if (tokens[1] > 0) {
                // in case 0x swapped just some amount of tokens and returned everything else
                if (tokens[1] != _amount) {
                    (wrapper, price) = getBestPrice(
                        tokens[1],
                        orderAddresses[1],
                        orderAddresses[2],
                        _exchangeType
                    );
                }

                // in case 0x failed, price on other exchanges still needs to be higher than minPrice
                require(price > _minPrice, "Slippage hit onchain price");
                if (orderAddresses[1] == KYBER_ETH_ADDRESS) {
                    (tokens[0], ) = ExchangeInterface(wrapper).swapEtherToToken.value(tokens[1])(
                        tokens[1],
                        orderAddresses[2],
                        uint256(-1)
                    );
                } else {
                    ERC20(orderAddresses[1]).transfer(wrapper, tokens[1]);

                    if (orderAddresses[2] == KYBER_ETH_ADDRESS) {
                        tokens[0] = ExchangeInterface(wrapper).swapTokenToEther(
                            orderAddresses[1],
                            tokens[1],
                            uint256(-1)
                        );
                    } else {
                        tokens[0] = ExchangeInterface(wrapper).swapTokenToToken(
                            orderAddresses[1],
                            orderAddresses[2],
                            tokens[1]
                        );
                    }
                }

                logger.emitSwap(orderAddresses[1], orderAddresses[2], _amount, tokens[0], wrapper);
            }
        }

        // return whatever is left in contract
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }

        // return if there is any tokens left
        if (orderAddresses[2] != KYBER_ETH_ADDRESS) {
            if (ERC20(orderAddresses[2]).balanceOf(address(this)) > 0) {
                ERC20(orderAddresses[2]).transfer(
                    msg.sender,
                    ERC20(orderAddresses[2]).balanceOf(address(this))
                );
            }
        }

        if (orderAddresses[1] != KYBER_ETH_ADDRESS) {
            if (ERC20(orderAddresses[1]).balanceOf(address(this)) > 0) {
                ERC20(orderAddresses[1]).transfer(
                    msg.sender,
                    ERC20(orderAddresses[1]).balanceOf(address(this))
                );
            }
        }
    }

    // @notice Takes order from 0x and returns bool indicating if it is successful
    // @param _addresses [exchange, src, dst]
    // @param _data Data to send with call
    // @param _value Value to send with call
    // @param _amount Amount being sold
    function takeOrder(
        address[3] memory _addresses,
        bytes memory _data,
        uint256 _value,
        uint256 _amount
    ) private returns (bool, uint256, uint256) {
        bool success;

        // solhint-disable-next-line avoid-call-value
        (success, ) = _addresses[0].call.value(_value)(_data);

        uint256 tokensLeft = _amount;
        uint256 tokensReturned = 0;
        if (success) {
            // check how many tokens left from _src
            if (_addresses[1] == KYBER_ETH_ADDRESS) {
                tokensLeft = address(this).balance;
            } else {
                tokensLeft = ERC20(_addresses[1]).balanceOf(address(this));
            }

            // check how many tokens are returned
            if (_addresses[2] == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(
                    TokenInterface(WETH_ADDRESS).balanceOf(address(this))
                );
                tokensReturned = address(this).balance;
            } else {
                tokensReturned = ERC20(_addresses[2]).balanceOf(address(this));
            }
        }

        return (success, tokensReturned, tokensLeft);
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
    ) public returns (address, uint256) {
        uint256 expectedRateKyber;
        uint256 expectedRateUniswap;
        uint256 expectedRateOasis;

        if (_exchangeType == 1) {
            return (OASIS_WRAPPER, getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount));
        }

        if (_exchangeType == 2) {
            return (KYBER_WRAPPER, getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount));
        }

        if (_exchangeType == 3) {
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

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }

    // receive eth from wrappers
    function() external payable {}
}
