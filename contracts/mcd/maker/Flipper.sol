pragma solidity ^0.5.0;

contract Flipper {

    function bids(uint _bidId) public returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
    function tend(uint id, uint lot, uint bid) external;
    function dent(uint id, uint lot, uint bid) external;
    function deal(uint id) external;
}
