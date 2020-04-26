pragma solidity ^0.5.0;

contract CompoundOracleInterface {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}
