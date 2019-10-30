pragma solidity ^0.5.0;

import "../../interfaces/ERC20.sol";

contract MCDExchange {
    address public constant SAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public constant DAI_ADDRESS = 0x1D7e3a1A65a367db1D1D3F51A54aC01a2c4C92ff;

    function saiToDai(uint _amount) public {
        ERC20(DAI_ADDRESS).transfer(msg.sender, _amount);
    }

    function daiToSai(uint _amount) public {
        ERC20(SAI_ADDRESS).transfer(msg.sender, _amount);
    }
}
