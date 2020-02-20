pragma solidity ^0.5.0;

import "./TokenInterface.sol";
import "./PipInterface.sol";


contract PepInterface {
    function peek() public returns (bytes32, bool);
}


contract VoxInterface {
    function par() public returns (uint256);
}


contract TubInterface {
    event LogNewCup(address indexed lad, bytes32 cup);

    function open() public returns (bytes32);

    function join(uint256) public;

    function exit(uint256) public;

    function lock(bytes32, uint256) public;

    function free(bytes32, uint256) public;

    function draw(bytes32, uint256) public;

    function wipe(bytes32, uint256) public;

    function give(bytes32, address) public;

    function shut(bytes32) public;

    function bite(bytes32) public;

    function cups(bytes32) public returns (address, uint256, uint256, uint256);

    function gem() public returns (TokenInterface);

    function gov() public returns (TokenInterface);

    function skr() public returns (TokenInterface);

    function sai() public returns (TokenInterface);

    function vox() public returns (VoxInterface);

    function ask(uint256) public returns (uint256);

    function mat() public returns (uint256);

    function chi() public returns (uint256);

    function ink(bytes32) public returns (uint256);

    function tab(bytes32) public returns (uint256);

    function rap(bytes32) public returns (uint256);

    function per() public returns (uint256);

    function pip() public returns (PipInterface);

    function pep() public returns (PepInterface);

    function tag() public returns (uint256);

    function drip() public;

    function lad(bytes32 cup) public view returns (address);

    function bid(uint256 wad) public view returns (uint256);
}
