pragma solidity ^0.6.0;

import "../maker/Gem.sol";

abstract contract ValueLike {
    function peek() public virtual returns (uint, bool);
}

abstract contract VoxLike {
    function par() public virtual returns (uint);
}

abstract contract SaiTubLike {
    function skr() public virtual view returns (Gem);
    function gem() public virtual view returns (Gem);
    function gov() public virtual view returns (Gem);
    function sai() public virtual view returns (Gem);
    function pep() public virtual view returns (ValueLike);
    function vox() public virtual view returns (VoxLike);
    function bid(uint) public virtual view returns (uint);
    function ink(bytes32) public virtual view returns (uint);
    function tag() public virtual view returns (uint);
    function tab(bytes32) public virtual returns (uint);
    function rap(bytes32) public virtual returns (uint);
    function draw(bytes32, uint) public virtual;
    function shut(bytes32) public virtual;
    function exit(uint) public virtual;
    function give(bytes32, address) public virtual;
    function lad(bytes32 cup) public virtual view returns (address);
    function cups(bytes32) public virtual returns (address, uint, uint, uint);
}
