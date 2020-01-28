pragma solidity ^0.5.0;

import "../../interfaces/ExchangeInterface.sol";
import "../../interfaces/SaverExchangeInterface.sol";

import "../../constants/ConstantAddresses.sol";


/// @title Helper methods for integration with SaverExchange
contract ExchangeHelper is ConstantAddresses {

    /// @notice Swaps 2 tokens on the Saver Exchange
    /// @dev ETH is sent with Weth address
    /// @param _data [amount, minPrice, exchangeType, 0xPrice]
    /// @param _src Token address of the source token
    /// @param _dest Token address of the destination token
    /// @param _exchangeAddress Address of 0x exchange that should be called
    /// @param _callData data to call 0x exchange with
    function swap(uint[4] memory _data, address _src, address _dest, address _exchangeAddress, bytes memory _callData) internal returns (uint) {
        address wrapper;
        uint price;
        uint tokensReturned;
        bool success;

        _src = wethToKyberEth(_src);
        _dest = wethToKyberEth(_dest);

        // if _data[2] == 4 use 0x if possible
        if (_data[2] == 4) {
            if (_src != KYBER_ETH_ADDRESS) {
                ERC20(_src).approve(address(ERC20_PROXY_0X), _data[0]);
            }

            (success, tokensReturned) = takeOrder(_exchangeAddress, _callData, address(this).balance, _dest);

            // if specifically 4, then require it to be successfull
            require(success);
        }

        if (!success) {
            (wrapper, price) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(_data[0], _src, _dest, _data[2]);

            require(price > _data[1] || _data[3] > _data[1], "Slippage hit");

            // handle 0x exchange
            if (_data[3] > price) {
                if (_src != KYBER_ETH_ADDRESS) {
                    ERC20(_src).approve(address(ERC20_PROXY_0X), _data[0]);
                }
                (success, tokensReturned) = takeOrder(_exchangeAddress, _callData, address(this).balance, _dest);
            }

            if (!success) {
                if (_src == KYBER_ETH_ADDRESS) {
                    (tokensReturned,) = ExchangeInterface(wrapper).swapEtherToToken.value(_data[0])(_data[0], _dest, uint(-1));
                } else {
                    ERC20(_src).transfer(wrapper, _data[0]);

                    if (_dest == KYBER_ETH_ADDRESS) {
                        tokensReturned = ExchangeInterface(wrapper).swapTokenToEther(_src, _data[0], uint(-1));
                    } else {
                        tokensReturned = ExchangeInterface(wrapper).swapTokenToToken(_src, _dest, _data[0]);
                    }
                }
            }
        }

        return tokensReturned;
    }

        // @notice Takes order from 0x and returns bool indicating if it is successful
    // @param _exchange Address of exchange to be called
    // @param _data Data to send with call
    // @param _value Value to send with call
    // @param _dest Address of token/ETH returned
    function takeOrder(address _exchange, bytes memory _data, uint _value, address _dest) private returns(bool, uint) {
        bool success;
        bytes memory result;

        (success, result) = _exchange.call.value(_value)(_data);

        uint tokensReturned = 0;
        if (success){
            if (_dest == KYBER_ETH_ADDRESS) {
                tokensReturned = address(this).balance;
            } else {
                tokensReturned = ERC20(_dest).balanceOf(address(this));
            }
        }

        return (success, tokensReturned);
    }

    /// @notice Converts WETH -> Kybers Eth address
    /// @param _src Input address
    function wethToKyberEth(address _src) internal pure returns (address) {
        return _src == WETH_ADDRESS ? KYBER_ETH_ADDRESS : _src;
    }
}
