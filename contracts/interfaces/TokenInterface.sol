pragma solidity ^0.5.0;


contract TokenInterface {
    function allowance(address, address) public returns (uint256);

    function balanceOf(address) public returns (uint256);

    function approve(address, uint256) public;

    function transfer(address, uint256) public returns (bool);

    function transferFrom(address, address, uint256) public returns (bool);

    function deposit() public payable;

    function withdraw(uint256) public;
}
