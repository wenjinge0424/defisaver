pragma solidity ^0.6.0;

abstract contract ISAFEEngine {

    struct SAFE {
        uint256 lockedCollateral;
        uint256 generatedDebt;
    }

    struct CollateralType {
        uint256 debtAmount;
        uint256 accumulatedRates;
        uint256 safetyPrice;
        uint256 debtCeiling;
        uint256 debtFloor;
    }

    mapping (bytes32 => mapping (address => SAFE )) public safes;
    mapping (bytes32 => CollateralType) public collateralTypes;
    mapping (bytes32 => mapping (address => uint)) public tokenCollateral;

    function safeRights(address, address) virtual public view returns (uint);
    function coinBalance(address) virtual public view returns (uint);
    function modifySAFECollateralization(bytes32, address, address, address, int, int) virtual public;
    function approveSAFEModification(address) virtual public;
    function transferInternalCoins(address, address, uint) virtual public;
    // function fork(bytes32, address, address, int, int) virtual public;
}
