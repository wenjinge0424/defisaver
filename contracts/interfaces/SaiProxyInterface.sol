pragma solidity ^0.5.0;


contract SaiProxyInterface {
    function open(address tub_) public returns (bytes32);

    function give(address tub_, bytes32 cup, address lad) public;

    function lock(address tub_, bytes32 cup) public payable;

    function draw(address tub_, bytes32 cup, uint256 wad) public;

    function wipe(address tub_, bytes32 cup, uint256 wad, address otc_) public;

    function wipe(address tub_, bytes32 cup, uint256 wad) public;

    function free(address tub_, bytes32 cup, uint256 jam) public;

    function lockAndDraw(address tub_, uint256 wad) public payable returns (bytes32 cup);

    function wipeAndFree(address tub_, bytes32 cup, uint256 jam, uint256 wad) public payable;

    function wipeAndFree(address tub_, bytes32 cup, uint256 jam, uint256 wad, address otc_)
        public
        payable;

    function shut(address tub_, bytes32 cup) public;

    function shut(address tub_, bytes32 cup, address otc_) public;

    function createOpenLockAndDraw(address registry_, address tub_, uint256 wad)
        public
        payable
        returns (address proxy, bytes32 cup);
}
