pragma solidity ^0.5.0;

contract Jug {
    struct Ilk {
        uint256 duty;
        uint256  rho;
    }

    mapping (bytes32 => Ilk) public ilks;

    function drip(bytes32) public returns (uint);
}
