pragma solidity ^0.6.0;

import "../../interfaces/ERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/ExchangeInterface.sol";
import "../../interfaces/UniswapExchangeInterface.sol";
import "../../DS/DSMath.sol";
import "../../constants/ConstantAddresses.sol";

abstract contract UniswapFactoryInterface {
    function getExchange(address token) external view virtual returns (address exchange);
}

contract UniswapWrapper is DSMath, ConstantAddresses {

    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable returns (uint) {
        address uniswapExchangeAddr;
        uint destAmount;

        // // if we are selling ether
        if (_srcAddr == WETH_ADDRESS) {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr);

            destAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                ethToTokenTransferInput{value: _srcAmount}(1, block.timestamp + 1, msg.sender);
        }
        // if we are buying ether
        else if (_destAddr == WETH_ADDRESS) {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).approve(uniswapExchangeAddr, _srcAmount);

            destAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToEthTransferInput(_srcAmount, 1, block.timestamp + 1, msg.sender);
        }
        // if we are selling token to token
        else {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).approve(uniswapExchangeAddr, _srcAmount);

            destAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToTokenTransferInput(_srcAmount, 1, 1, block.timestamp + 1, msg.sender, _destAddr);
        }

        return destAmount;
    }

    function buy(address _srcAddr, address _destAddr, uint _destAmount) external payable returns(uint) {
        address uniswapExchangeAddr;
        uint destAmount;

        // if we are selling ether
        if (_srcAddr == WETH_ADDRESS) {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr);

            destAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                ethToTokenTransferOutput{value: msg.value}(_destAmount, block.timestamp + 1, msg.sender);
        }
         // if we are buying ether
        else if (_destAddr == WETH_ADDRESS) {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).approve(uniswapExchangeAddr, uint(-1));

            destAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToEthTransferOutput(_destAmount, uint(-1), block.timestamp + 1, msg.sender);
        }
        // if we are buying token to token
        else {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).approve(uniswapExchangeAddr, uint(-1));

            destAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToTokenTransferOutput(_destAmount, uint(-1), uint(-1), block.timestamp + 1, msg.sender, _destAddr);
        }

        // TODO: check if we got the exact amount

        return _destAmount;
    }

    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public view returns (uint) {
        if(_srcAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr);
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getEthToTokenInputPrice(_srcAmount), _srcAmount);
        } else if (_srcAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getTokenToEthInputPrice(_srcAmount), _srcAmount);
        } else {
            uint ethBought = UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr)).getTokenToEthInputPrice(_srcAmount);
            return wdiv(UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr)).getEthToTokenInputPrice(ethBought), _srcAmount);
        }
    }

    // TODO: check this calc.
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public view returns (uint) {
        if(_srcAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr);
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getEthToTokenOutputPrice(_destAmount), _destAmount);
        } else if (_srcAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getTokenToEthOutputPrice(_destAmount), _destAmount);
        } else {
            uint ethSold = UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr)).getTokenToEthOutputPrice(_destAmount);
            return wdiv(UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr)).getEthToTokenOutputPrice(ethSold), _destAmount);
        }
    }

    receive() payable external {}
}
