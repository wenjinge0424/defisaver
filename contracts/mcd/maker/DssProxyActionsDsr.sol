pragma solidity ^0.5.0;

contract DssProxyActionsDsr {
    function join(address daiJoin, address pot, uint wad) public;
    function exit(address daiJoin, address pot, uint wad) public;
    function exitAll(address daiJoin, address pot) public;
}
