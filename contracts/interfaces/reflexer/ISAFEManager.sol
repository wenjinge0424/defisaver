pragma solidity ^0.6.0;

abstract contract ISAFEManager {
    address public safeEngine;

    // function last(address) virtual public returns (uint);
    // function cdpCan(address, uint, address) virtual public view returns (uint);
    function collateralTypes(uint) virtual public view returns (bytes32);
    function ownsSAFE(uint) virtual public view returns (address);
    function safes(uint) virtual public view returns (address);
    // function vat() virtual public view returns (address);
    // function open(bytes32, address) virtual public returns (uint);
    // function give(uint, address) virtual public;
    function safeAllowed(uint, address, uint) virtual public;
    // function urnAllow(address, uint) virtual public;
    function modifySAFECollateralization(uint, int, int) virtual public;
    function transferCollateral(uint, address, uint) virtual public;
    function transferInternalCoins(uint, address, uint) virtual public;
    // function exit(address, uint, address, uint) virtual public;
    // function quit(uint, address) virtual public;
    // function enter(address, uint) virtual public;
    // function shift(uint, uint) virtual public;
}
