pragma solidity ^0.5.0;

import "./Vat.sol";
import "./Gem.sol";

contract DaiJoin {
    function vat() public returns (Vat);
    function dai() public returns (Gem);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}
