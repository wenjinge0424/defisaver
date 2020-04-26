pragma solidity ^0.5.0;

import "./DSProxyInterface.sol";


contract ProxyRegistryInterface {
    function proxies(address _owner) public view returns (address);
    function build(address) public returns (address);
}
