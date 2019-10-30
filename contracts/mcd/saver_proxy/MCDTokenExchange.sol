pragma solidity ^0.5.0;

import "../../interfaces/ERC20.sol";

contract MCDTokenExchange {

    address public constant WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    mapping (address => address) public newOld;

    function oldToNew(address _newToken, uint _amount) public {
        if (isEth(_newToken)) return;

        ERC20(_newToken).transfer(msg.sender, _amount);
    }

    function newToOld(address _newToken, uint _amount) public {
        if (isEth(_newToken)) return;

        ERC20(newOld[_newToken]).transfer(msg.sender, _amount);
    }

    function getOld(address _newToken) public view returns (address) {
        if (isEth(_newToken)) return WETH_ADDRESS;

        return newOld[_newToken];
    }

    function isEth(address _token) internal pure returns (bool) {
        return _token == WETH_ADDRESS ? true : false;
    }

    function addToken(address _oldToken, address _newToken) public {
        newOld[_newToken] = _oldToken;
    }
}
