pragma solidity ^0.5.0;

import "../../interfaces/ExchangeInterface.sol";

contract SaverExchangeInterface {
    function getBestPrice(uint _amount, address _srcToken, address _destToken, uint _exchangeType) public view returns (address, uint);
}

contract ExchangeHelper {
    address public constant WETH_ADDRESS = 0x1f9BEAf12D8db1e50eA8a5eD53FB970462386aA0;
    address public constant SAVER_EXCHANGE_ADDRESS = 0x1f9BEAf12D8db1e50eA8a5eD53FB970462386aA0;

    function swap(address _src, address _dest, uint _amount, uint _minPrice, uint _exchangeType) public payable returns (uint) {
        address wrapper;
        uint price;

        (wrapper, price) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(_amount, _src, _dest, _exchangeType);

        require(price > _minPrice, "Slippage hit");

        uint tokensReturned;
        if (_src == WETH_ADDRESS) {
            (tokensReturned,) = ExchangeInterface(wrapper).swapEtherToToken.value(_amount)(_amount, _dest, uint(-1));
        } else {
            ERC20(_src).transfer(wrapper, _amount);

            if (_dest == WETH_ADDRESS) {
                tokensReturned = ExchangeInterface(wrapper).swapTokenToEther(_src, _amount, uint(-1));
            } else {
                tokensReturned = ExchangeInterface(wrapper).swapTokenToToken(_src, _dest, _amount);
            }
        }

        return tokensReturned;
    }
}
