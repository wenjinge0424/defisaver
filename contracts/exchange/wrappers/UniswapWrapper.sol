pragma solidity ^0.6.0;

import "../../interfaces/ERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/ExchangeInterface.sol";
import "../../interfaces/UniswapExchangeInterface.sol";
import "../../interfaces/UniswapFactoryInterface.sol";
import "../../DS/DSMath.sol";
import "../../constants/ConstantAddresses.sol";

contract UniswapWrapper is DSMath, ConstantAddresses {

    /// @notice Sells a _srcAmount of tokens at Uniswap
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
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

    /// @notice Buys a _destAmount of tokens at Uniswap
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount) external payable returns(uint) {
        address uniswapExchangeAddr;
        uint srcAmount;

        // if we are selling ether
        if (_srcAddr == WETH_ADDRESS) {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr);

            srcAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                ethToTokenTransferOutput{value: msg.value}(_destAmount, block.timestamp + 1, msg.sender);
        }
         // if we are buying ether
        else if (_destAddr == WETH_ADDRESS) {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).approve(uniswapExchangeAddr, uint(-1));

            srcAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToEthTransferOutput(_destAmount, uint(-1), block.timestamp + 1, msg.sender);
        }
        // if we are buying token to token
        else {
            uniswapExchangeAddr = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);

            ERC20(_srcAddr).approve(uniswapExchangeAddr, uint(-1));

            srcAmount = UniswapExchangeInterface(uniswapExchangeAddr).
                tokenToTokenTransferOutput(_destAmount, uint(-1), uint(-1), block.timestamp + 1, msg.sender, _destAddr);
        }

        // Send the leftover from the source token back
        sendLeftOver(_srcAddr);

        return srcAmount;
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Rate
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

    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public view returns (uint) {
        if(_srcAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr);
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getEthToTokenOutputPrice(_destAmount), _destAmount);
        } else if (_srcAddr == WETH_ADDRESS) {
            address uniswapTokenAddress = UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr);
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getTokenToEthOutputPrice(_destAmount), _destAmount);
        } else {
            uint ethNeeded = UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_destAddr)).getTokenToEthOutputPrice(_destAmount);
            return wdiv(UniswapExchangeInterface(UniswapFactoryInterface(UNISWAP_FACTORY).getExchange(_srcAddr)).getEthToTokenOutputPrice(ethNeeded), _destAmount);
        }
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
    function sendLeftOver(address _srcAddr) internal {
        if (_srcAddr == WETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_srcAddr).transfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    receive() payable external {}
}
