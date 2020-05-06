pragma solidity ^0.6.0;


abstract contract SaiProxyInterface {
    function open(address tub_) public virtual returns (bytes32);

    function give(address tub_, bytes32 cup, address lad) public virtual;

    function lock(address tub_, bytes32 cup) public virtual payable;

    function draw(address tub_, bytes32 cup, uint256 wad) public virtual;

    function wipe(address tub_, bytes32 cup, uint256 wad, address otc_) public virtual;

    function wipe(address tub_, bytes32 cup, uint256 wad) public virtual;

    function free(address tub_, bytes32 cup, uint256 jam) public virtual;

    function lockAndDraw(address tub_, uint256 wad) public virtual payable returns (bytes32 cup);

    function wipeAndFree(address tub_, bytes32 cup, uint256 jam, uint256 wad) public virtual payable;

    function wipeAndFree(address tub_, bytes32 cup, uint256 jam, uint256 wad, address otc_)
        public virtual
        payable;

    function shut(address tub_, bytes32 cup) public virtual;

    function shut(address tub_, bytes32 cup, address otc_) public virtual;

    function createOpenLockAndDraw(address registry_, address tub_, uint256 wad)
        public virtual
        payable
        returns (address proxy, bytes32 cup);
}
