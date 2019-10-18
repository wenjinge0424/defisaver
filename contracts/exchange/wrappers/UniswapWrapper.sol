pragma solidity ^0.5.0;

import "../../interfaces/ERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/ExchangeInterface.sol";
import "../../interfaces/UniswapExchangeInterface.sol";
import "../../DS/DSMath.sol";
import "../../constants/ConstantAddresses.sol";

contract UniswapFactoryInterface {
    function getExchange(address token) external view returns (address exchange);
}

contract UniswapWrapper is ExchangeInterface, DSMath, ConstantAddresses {

    // Mainnet, no kovan deployment :(
    // address public constant UNISWAP_FACTORY = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;

    function swapTokenToToken(address _src, address _dest, uint _amount) external payable returns(uint) {
        require(_src != KYBER_ETH_ADDRESS && _dest != KYBER_ETH_ADDRESS);

        address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_src);

        ERC20(_src).approve(uniswapTokenAddress, _amount);

        uint destAmount = UniswapExchangeInterface(uniswapTokenAddress).
                tokenToTokenTransferInput(_amount, 0, 0, block.timestamp + 1, msg.sender, _dest);

        return destAmount;
    }

    function swapEtherToToken(uint _ethAmount, address _tokenAddress, uint _maxAmount) external payable returns(uint, uint) {
        address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_tokenAddress);

        uint tokenAmount = UniswapExchangeInterface(uniswapTokenAddress).
                ethToTokenTransferInput.value(_ethAmount)(1, block.timestamp + 1, msg.sender);

        return (tokenAmount, 0);
    }

    function swapTokenToEther(address _tokenAddress, uint _amount, uint _maxAmount) external returns(uint) {
        address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_tokenAddress);

        ERC20(_tokenAddress).approve(uniswapTokenAddress, _amount);

        uint ethAmount = UniswapExchangeInterface(uniswapTokenAddress).
                tokenToEthTransferInput(_amount, 1, block.timestamp + 1, msg.sender);

        return ethAmount;
    }

    function getExpectedRate(address _src, address _dest, uint _srcQty) public view returns (uint, uint) {
        if(_src == KYBER_ETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_dest);
            return (wdiv(UniswapExchangeInterface(uniswapTokenAddress).getEthToTokenInputPrice(_srcQty), _srcQty), 0);
        } else if (_dest == KYBER_ETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_src);
            return (wdiv(UniswapExchangeInterface(uniswapTokenAddress).getTokenToEthInputPrice(_srcQty), _srcQty), 0);
        } else {
            uint ethBought = UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_src)).getTokenToEthInputPrice(_srcQty);
            return (wdiv(UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_dest)).getEthToTokenInputPrice(ethBought), ethBought), 0);
        }
    }

    function() payable external {
    }
}
