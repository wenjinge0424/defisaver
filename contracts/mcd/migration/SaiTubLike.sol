pragma solidity ^0.5.0;

import "../maker/Gem.sol";

contract ValueLike {
    function peek() public returns (uint, bool);
}

contract VoxLike {
    function par() public returns (uint);
}

contract SaiTubLike {
    function skr() public view returns (Gem);
    function gem() public view returns (Gem);
    function gov() public view returns (Gem);
    function sai() public view returns (Gem);
    function pep() public view returns (ValueLike);
    function vox() public view returns (VoxLike);
    function bid(uint) public view returns (uint);
    function ink(bytes32) public view returns (uint);
    function tag() public view returns (uint);
    function tab(bytes32) public returns (uint);
    function rap(bytes32) public returns (uint);
    function draw(bytes32, uint) public;
    function shut(bytes32) public;
    function exit(uint) public;
    function give(bytes32, address) public;
    function cups(bytes32) public returns (address, uint, uint, uint);
}
