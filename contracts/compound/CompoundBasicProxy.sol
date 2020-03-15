pragma solidity ^0.5.0;

import "../interfaces/CTokenInterface.sol";
import "../interfaces/ERC20.sol";

contract CEtherInterface {
    function mint() external payable;
}

contract CompoundBasicProxy {

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    function deposit(address _tokenAddr, address _cTokenAddr, uint _amount) external payable {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).approve(_cTokenAddr, uint(-1));
        }

        if (_tokenAddr != ETH_ADDRESS) {
            require(CTokenInterface(_cTokenAddr).mint(_amount) == 0);
        } else {
            CEtherInterface(_cTokenAddr).mint.value(msg.value)(); // reverts on fail
        }
    }

    /// @param _isCAmount If true _amount is cTokens if falls _amount is underlying tokens
    function withdraw(address _tokenAddr, address _cTokenAddr, uint _amount, bool _isCAmount) external {

        if (_isCAmount) {
            require(CTokenInterface(_cTokenAddr).redeem(_amount) == 0);
        } else {
            require(CTokenInterface(_cTokenAddr).redeemUnderlying(_amount) == 0);
        }

        // withdraw funds to msg.sender
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).transfer(msg.sender, ERC20(_tokenAddr).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }

    }

    function borrow(address _tokenAddr, address _cTokenAddr, uint _amount) external {
        require(CTokenInterface(_cTokenAddr).borrow(_amount) == 0);

        // withdraw funds to msg.sender
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).transfer(msg.sender, ERC20(_tokenAddr).balanceOf(address(this)));
        } else {
            msg.sender.transfer(address(this).balance);
        }
    }


    function payback(address _tokenAddr, address _cTokenAddr, uint _amount) external {

    }

    function withdrawCTokens() external {

    }
}