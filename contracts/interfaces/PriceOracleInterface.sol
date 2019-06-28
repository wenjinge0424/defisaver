pragma solidity ^0.5.0;

contract PriceOracleInterface {
    function getPrice(address asset) public view returns (uint);
}
