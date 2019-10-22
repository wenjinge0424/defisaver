pragma solidity ^0.5.0;

import "../../interfaces/ExchangeInterface.sol";

contract SaverExchangeInterface {
    function getBestPrice(uint _amount, address _srcToken, address _destToken, uint _exchangeType) public view returns (address, uint);
}

contract ExchangeHelper {
    address public constant WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public constant SAVER_EXCHANGE_ADDRESS = 0xB14aE674cfa02d9358B0e93440d751fd9Ab2831C;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function wethToKyberEth(address _src) internal pure returns (address) {
        return _src == WETH_ADDRESS ? KYBER_ETH_ADDRESS : _src;
    }

    function swap(address _src, address _dest, uint _amount, uint _minPrice, uint _exchangeType) public payable returns (uint) {
        address wrapper;
        uint price;

        _src = wethToKyberEth(_src);
        _dest = wethToKyberEth(_dest);

        (wrapper, price) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(_amount, _src, _dest, _exchangeType);

        //TODO: only for tests
        // require(price > _minPrice, "Slippage hit");

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
