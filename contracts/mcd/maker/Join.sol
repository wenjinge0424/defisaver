pragma solidity ^0.5.0;

import "./Gem.sol";

contract Join {
    bytes32 public ilk;

    function dec() public view returns (uint);
    function gem() public returns (Gem);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}
