pragma solidity ^0.5.0;

import "./ERC20.sol";

contract GasTokenInterface is ERC20 {
    function free(uint256 value) public returns (bool success);
    function freeUpTo(uint256 value) public returns (uint256 freed);
    function freeFrom(address from, uint256 value) public returns (bool success);
    function freeFromUpTo(address from, uint256 value) public returns (uint256 freed);
}