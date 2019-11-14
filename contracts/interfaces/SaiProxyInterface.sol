pragma solidity ^0.5.0;

contract SaiProxyInterface {
    function open(address tub_) public returns (bytes32);
    function give(address tub_, bytes32 cup, address lad) public;
    function lock(address tub_, bytes32 cup) public payable;
    function draw(address tub_, bytes32 cup, uint wad) public;
    function wipe(address tub_, bytes32 cup, uint wad, address otc_) public;
    function wipe(address tub_, bytes32 cup, uint wad) public;
    function free(address tub_, bytes32 cup, uint jam) public;
    function lockAndDraw(address tub_, uint wad) public payable returns (bytes32 cup);
    function wipeAndFree(address tub_, bytes32 cup, uint jam, uint wad) public payable;
    function wipeAndFree(address tub_, bytes32 cup, uint jam, uint wad, address otc_) public payable;
    function shut(address tub_, bytes32 cup) public;
    function shut(address tub_, bytes32 cup, address otc_) public;

    function createOpenLockAndDraw(address registry_, address tub_, uint wad) public payable returns (address proxy, bytes32 cup);
}
