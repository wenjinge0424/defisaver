pragma solidity ^0.6.0;

import "../../interfaces/ExchangeInterface.sol";
import "../../interfaces/OasisInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/TokenInterface.sol";
import "../../constants/ConstantAddresses.sol";
import "../../DS/DSMath.sol";

contract OasisTradeWrapper is DSMath, ConstantAddresses {

    /// @notice Sells a _srcAmount of tokens at Oasis
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Destination amount
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        require(ERC20(srcAddr).approve(OTC_ADDRESS, _srcAmount));

        // convert eth -> weth
        if (srcAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).deposit{value: _srcAmount}();
        }

        uint destAmount = OasisInterface(OTC_ADDRESS).sellAllAmount(srcAddr, _srcAmount, destAddr, 0);

        // convert weth -> eth and send back
        if (destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(destAmount);
            msg.sender.transfer(destAmount);
        } else {
            ERC20(destAddr).transfer(msg.sender, destAmount);
        }

        return destAmount;
    }

    /// @notice Buys a _destAmount of tokens at Oasis
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint srcAmount
    function buy(address _srcAddr, address _destAddr, uint _destAmount) external payable returns(uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        require(ERC20(srcAddr).approve(OTC_ADDRESS, uint(-1)));

        // convert eth -> weth
        if (srcAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).deposit{value: msg.value}();
        }

        uint srcAmount = OasisInterface(OTC_ADDRESS).buyAllAmount(srcAddr, _destAmount, destAddr, uint(-1));

        // convert weth -> eth and send back
        if (destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(_destAmount);
            msg.sender.transfer(_destAmount);
        } else {
            ERC20(destAddr).transfer(msg.sender, _destAmount);
        }

        // Send the leftover from the source token back
        sendLeftOver(srcAddr);

        return srcAmount;
    }

    /// @notice Return a rate for which we can sell an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _srcAmount From amount
    /// @return uint Rate
    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public view returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        return wdiv(OasisInterface(OTC_ADDRESS).getBuyAmount(destAddr, srcAddr, _srcAmount), _srcAmount);
    }

    /// @notice Return a rate for which we can buy an amount of tokens
    /// @param _srcAddr From token
    /// @param _destAddr To token
    /// @param _destAmount To amount
    /// @return uint Rate
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public view returns (uint) {
        address srcAddr = ethToWethAddr(_srcAddr);
        address destAddr = ethToWethAddr(_destAddr);

        return wdiv(OasisInterface(OTC_ADDRESS).getPayAmount(destAddr, srcAddr, _destAmount), _destAmount);
    }

    /// @notice Send any leftover tokens, we use to clear out srcTokens after buy
    /// @param _srcAddr Source token address
    function sendLeftOver(address _srcAddr) internal {
         address srcAddr = ethToWethAddr(_srcAddr);

        if (srcAddr == WETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(srcAddr).transfer(msg.sender, ERC20(srcAddr).balanceOf(address(this)));
        }
    }

    /// @notice Converts Kybers Eth address -> Weth
    /// @param _src Input address
    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }


    receive() payable external {}
}
