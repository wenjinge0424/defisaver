pragma solidity ^0.6.0;

import "../../interfaces/ExchangeInterface.sol";
import "../../interfaces/OasisInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/TokenInterface.sol";
import "../../constants/ConstantAddresses.sol";
import "../../DS/DSMath.sol";

contract OasisTradeWrapper is DSMath, ConstantAddresses {

    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable returns (uint) {
        require(ERC20(_srcAddr).approve(OTC_ADDRESS, _srcAmount));

        // convert eth -> weth
        if (_srcAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).deposit{value: _srcAmount}();
        }

        uint destAmount = OasisInterface(OTC_ADDRESS).sellAllAmount(_srcAddr, _srcAmount, _destAddr, 0);

        // convert weth -> eth and send back
        if (_destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(destAmount);
            msg.sender.transfer(destAmount);
        } else {
            ERC20(_destAddr).transfer(msg.sender, destAmount);
        }

        return destAmount;
    }

    function buy(address _srcAddr, address _destAddr, uint _destAmount) external payable returns(uint) {
        require(ERC20(_srcAddr).approve(OTC_ADDRESS, uint(-1)));

        // convert eth -> weth
        if (_srcAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).deposit{value: msg.value}();
        }

        uint srcAmount = OasisInterface(OTC_ADDRESS).buyAllAmount(_srcAddr, _destAmount, _destAddr, uint(-1));

        // convert weth -> eth and send back
        if (_destAddr == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(_destAmount);
            msg.sender.transfer(_destAmount);
        } else {
            ERC20(_destAddr).transfer(msg.sender, _destAmount);
        }

        // Send the leftover from the source token back
        sendLeftOver(_srcAddr);

        return srcAmount;
    }

    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public view returns (uint) {
        return wdiv(OasisInterface(OTC_ADDRESS).getBuyAmount(_destAddr, _srcAddr, _srcAmount), _srcAmount);
    }

    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public view returns (uint) {
        return wdiv(OasisInterface(OTC_ADDRESS).getPayAmount(_destAddr, _srcAddr, _destAmount), _destAmount);
    }

    function sendLeftOver(address _srcAddr) internal {
        if (_srcAddr == WETH_ADDRESS) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_srcAddr).transfer(msg.sender, ERC20(_srcAddr).balanceOf(address(this)));
        }
    }

    receive() payable external {}
}
