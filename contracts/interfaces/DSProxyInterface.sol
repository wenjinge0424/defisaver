pragma solidity ^0.5.0;

contract DSProxyInterface {
    function execute(bytes memory _code, bytes memory _data) public payable returns (address, bytes32);

    function execute(address _target, bytes memory _data) public payable returns (bytes32);

    function setCache(address _cacheAddr) public payable returns (bool);

    function owner() public returns (address);
}
