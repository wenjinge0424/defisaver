pragma solidity ^0.5.0;


contract DSSProxyActions {
    function open(address manager, bytes32 ilk) public returns (uint cdp);
    function lockETH(address manager, address ethJoin, uint cdp) public payable;
    function draw(address manager, address jug, address daiJoin, uint cdp, uint wad) public;
}
