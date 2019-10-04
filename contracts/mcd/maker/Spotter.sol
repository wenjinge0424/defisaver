pragma solidity ^0.5.0;

import "../../interfaces/PipInterface.sol";

contract Spotter {
    struct Ilk {
        PipInterface pip;
        uint256 mat;
    }

    mapping (bytes32 => Ilk) public ilks;

}
