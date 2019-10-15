pragma solidity ^0.5.0;

import "../interfaces/ERC20.sol";
import "../interfaces/Eth2DaiInterface.sol";
import "../interfaces/TokenInterface.sol";
import "../DS/DSMath.sol";
import "../constants/ConstantAddresses.sol";

contract OasisTrade is DSMath, ConstantAddresses {
    function swap(address _srcToken, address _dstToken, uint _amount) external payable returns(uint) {
        require(ERC20(_srcToken).approve(OTC_ADDRESS, _amount));

        if (_srcToken == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).deposit.value(_amount)(); // to WETH
        } else {
            require(ERC20(_srcToken).transferFrom(msg.sender, address(this), _amount));
        }

        uint dstAmount = Eth2DaiInterface(OTC_ADDRESS).sellAllAmount(ERC20(_srcToken), _amount,
                 ERC20(_dstToken), 0);


        if (_dstToken == WETH_ADDRESS) {
            TokenInterface(WETH_ADDRESS).withdraw(dstAmount); // from WETH
            msg.sender.transfer(dstAmount);

            return dstAmount;
        }

        ERC20(_dstToken).transfer(msg.sender, dstAmount);

        return dstAmount;
    }

    function() payable external {}
}
