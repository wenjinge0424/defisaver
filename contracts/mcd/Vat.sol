pragma solidity ^0.5.0;

contract Vat {
    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
}
