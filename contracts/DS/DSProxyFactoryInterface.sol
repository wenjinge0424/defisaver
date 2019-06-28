pragma solidity 0.5.0;

import "./DSProxy.sol";

contract DSProxyFactoryInterface {
    function build(address owner) public returns (DSProxy proxy);
}