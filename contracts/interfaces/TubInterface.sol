pragma solidity ^0.6.0;

import "./TokenInterface.sol";
import "./PipInterface.sol";


abstract contract PepInterface {
    function peek() public virtual returns (bytes32, bool);
}


abstract contract VoxInterface {
    function par() public virtual returns (uint256);
}


abstract contract TubInterface {
    event LogNewCup(address indexed lad, bytes32 cup);

    function open() public virtual returns (bytes32);

    function join(uint256) public virtual;

    function exit(uint256) public virtual;

    function lock(bytes32, uint256) public virtual;

    function free(bytes32, uint256) public virtual;

    function draw(bytes32, uint256) public virtual;

    function wipe(bytes32, uint256) public virtual;

    function give(bytes32, address) public virtual;

    function shut(bytes32) public virtual;

    function bite(bytes32) public virtual;

    function cups(bytes32) public virtual returns (address, uint256, uint256, uint256);

    function gem() public virtual returns (TokenInterface);

    function gov() public virtual returns (TokenInterface);

    function skr() public virtual returns (TokenInterface);

    function sai() public virtual returns (TokenInterface);

    function vox() public virtual returns (VoxInterface);

    function ask(uint256) public virtual returns (uint256);

    function mat() public virtual returns (uint256);

    function chi() public virtual returns (uint256);

    function ink(bytes32) public virtual returns (uint256);

    function tab(bytes32) public virtual returns (uint256);

    function rap(bytes32) public virtual returns (uint256);

    function per() public virtual returns (uint256);

    function pip() public virtual returns (PipInterface);

    function pep() public virtual returns (PepInterface);

    function tag() public virtual returns (uint256);

    function drip() public virtual;

    function lad(bytes32 cup) public virtual view returns (address);

    function bid(uint256 wad) public virtual view returns (uint256);
}
