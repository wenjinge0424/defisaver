pragma solidity ^0.5.0;

import "../interfaces/ExchangeInterface.sol";
import "../interfaces/TokenInterface.sol";
import "../DS/DSMath.sol";
import "../constants/ConstantAddresses.sol";
import "../Discount.sol";

contract SaverExchange is DSMath, ConstantAddresses {

    uint public constant SERVICE_FEE = 800; // 0.125% Fee

    event Swap(address src, address dest, uint amountSold, uint amountBought, address wrapper);

    function swapTokenToToken(address _src, address _dest, uint _amount, uint _minPrice, uint _exchangeType, address _exchangeAddress, bytes memory _callData, uint _0xPrice) public payable {
        if (_src == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount);
        } else {
            require(ERC20(_src).transferFrom(msg.sender, address(this), _amount));
        }

        uint fee = takeFee(_amount, _src);
        _amount = sub(_amount, fee);
        uint tokensReturned;
        address wrapper;
        uint price;
        bool success;

        if (_exchangeType == 4) {
            if (_src != KYBER_ETH_ADDRESS) {
                ERC20(_src).approve(address(ERC20_PROXY_0X), _amount);
            }

            (success, tokensReturned) = takeOrder(_exchangeAddress, _callData, address(this).balance, _dest);
            // either it reverts or order doesn't exist anymore
            if (success && tokensReturned > 0) {
                wrapper = address(_exchangeAddress);
            }
        }

        if (tokensReturned == 0) {
            (wrapper, price) = getBestPrice(_amount, _src, _dest, _exchangeType);

            require(price > _minPrice || _0xPrice > _minPrice, "Slippage hit");

            // handle 0x exchange
            if (_0xPrice > price) {
                if (_src != KYBER_ETH_ADDRESS) {
                    ERC20(_src).approve(address(ERC20_PROXY_0X), _amount);
                }
                (success, tokensReturned) = takeOrder(_exchangeAddress, _callData, address(this).balance, _dest);
                // either it reverts or order doesn't exist anymore
                if (success && tokensReturned > 0) {
                    wrapper = address(_exchangeAddress);
                }
            }

            if (tokensReturned == 0) {
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
            }
        }

        // return whatever is left in contract
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }

        // return if there is any tokens left
        if (_dest != KYBER_ETH_ADDRESS) {
            if (ERC20(_dest).balanceOf(address(this)) > 0) {
                ERC20(_dest).transfer(msg.sender, ERC20(_dest).balanceOf(address(this)));
            }
        }

        if (_src != KYBER_ETH_ADDRESS) {
            if (ERC20(_src).balanceOf(address(this)) > 0) {
                ERC20(_src).transfer(msg.sender, ERC20(_src).balanceOf(address(this)));
            }
        }

        emit Swap(_src, _dest, _amount, tokensReturned, wrapper);
    }

    // @notice Takes order from 0x and returns bool indicating if it is successful
    // @param _exchange Address of exchange to be called
    // @param _data Data to send with call
    // @param _value Value to send with call
    // @param _dest Address of token/ETH returned
    function takeOrder(address _exchange, bytes memory _data, uint _value, address _dest) private returns(bool, uint) {
        bool success;

        (success, ) = _exchange.call.value(_value)(_data);

        uint tokensReturned = 0;
        if (success){
            if (_dest == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(TokenInterface(WETH_ADDRESS).balanceOf(address(this)));
                tokensReturned = address(this).balance;
            } else {
                tokensReturned = ERC20(_dest).balanceOf(address(this));
            }
        }

        return (success, tokensReturned);
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
            return (OASIS_WRAPPER, expectedRateOasis);
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
