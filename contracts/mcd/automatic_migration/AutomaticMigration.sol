pragma solidity ^0.6.0;

import "../../DS/DSMath.sol";
import "../migration/SaiTubLike.sol";
import "../maker/ScdMcdMigration.sol";
import "../../constants/ConstantAddresses.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../maker/Manager.sol";
import "../maker/Join.sol";

contract AutomaticMigration is DSMath, ConstantAddresses {

    enum MigrationType { WITH_MKR, WITH_CONVERSION, WITH_DEBT }

    bytes32 SAI_ILK = 0x5341490000000000000000000000000000000000000000000000000000000000;

    uint MAX_GAS_PRICE = 50000000000;

    address public constant CUSTOM_MIGRATION_ACTIONS_PROXY = 0xc2429Ea56D3Eb580c9bda2A8ee08Fb8837Cb400c;

    struct Subscription {
        bytes32 cdpId;
        address owner;
        MigrationType migType;
    }

    address payable public owner;
    uint public changeIndex;

    mapping (address => bool) public approvedCallers;
    mapping (bytes32 => Subscription) public subscribers;

    ScdMcdMigration public migrationContract = ScdMcdMigration(SCD_MCD_MIGRATION);
    SaiTubLike public tubContract = SaiTubLike(TUB_ADDRESS);
    Vat public vat = Vat(VAT_ADDRESS);
    Manager public manager = Manager(MANAGER_ADDRESS);

    modifier isApprovedCaller() {
        require(approvedCallers[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    event Subscribed(address indexed owner, bytes32 cdpId, MigrationType migType);
    event Unsubscribed(address indexed owner, bytes32 cdpId);
    event Migrated(bytes32 indexed oldCdp, uint indexed newCdp, address owner, uint timestamp);

    constructor() public {
        owner = msg.sender;
        approvedCallers[owner] = true;
    }

    function subscribe(bytes32 _cdpId, MigrationType _type) external {
        require(subscribers[_cdpId].owner == address(0x0));
        require(isOwner(msg.sender, _cdpId));

        subscribers[_cdpId] = Subscription({
            cdpId: _cdpId,
            owner: msg.sender,
            migType: _type
        });

        changeIndex++;

        emit Subscribed(msg.sender, _cdpId, _type);
    }

    function unsubscribe(bytes32 _cdpId) external {
        require(subscribers[_cdpId].owner != address(0x0));
        require(isOwner(msg.sender, _cdpId));

        delete subscribers[_cdpId];

        changeIndex++;

        emit Unsubscribed(msg.sender, _cdpId);
    }

    function migrateFor(bytes32 _cdpId) external isApprovedCaller() {
        uint256 startGas = gasleft();

        require(subscribers[_cdpId].cdpId == _cdpId);

        require(hasEnoughLiquidity(_cdpId));

        MigrationType migType = subscribers[_cdpId].migType;

        if (migType == MigrationType.WITH_MKR) {
            DSProxyInterface(subscribers[_cdpId].owner).execute(CUSTOM_MIGRATION_ACTIONS_PROXY,
                abi.encodeWithSignature("migrate(address,bytes32)", SCD_MCD_MIGRATION, _cdpId));
        } else if (migType == MigrationType.WITH_CONVERSION) {
            DSProxyInterface(subscribers[_cdpId].owner).execute(CUSTOM_MIGRATION_ACTIONS_PROXY,
                abi.encodeWithSignature("migratePayFeeWithGem(address,bytes32,address,address,uint256)", SCD_MCD_MIGRATION, _cdpId, OTC_ADDRESS, MAKER_DAI_ADDRESS, uint(-1)));
        } else if (migType == MigrationType.WITH_DEBT) {
             DSProxyInterface(subscribers[_cdpId].owner).execute(CUSTOM_MIGRATION_ACTIONS_PROXY,
                abi.encodeWithSignature("migratePayFeeWithDebt(address,bytes32,address,uint256,uint256)", SCD_MCD_MIGRATION, _cdpId, OTC_ADDRESS, uint(-1), 0));
        }

        uint newVault = manager.last(subscribers[_cdpId].owner);

        uint currGasLeft = gasleft();
        uint gasCost = calcTxCost(startGas, currGasLeft);

        // Draw eth to pay for gas cost
        DSProxyInterface(subscribers[_cdpId].owner).execute(PROXY_ACTIONS,
                abi.encodeWithSignature("freeETH(address,address,uint256,uint256)", MANAGER_ADDRESS, ETH_JOIN_ADDRESS, newVault, gasCost));

        emit Migrated(_cdpId, newVault, subscribers[_cdpId].owner, block.timestamp);
    }

    function hasEnoughLiquidity(bytes32 _cdpId) public returns (bool) {
        uint migrationSai;
        uint cdpDebt;

        (, migrationSai) = vat.urns(SAI_ILK, SCD_MCD_MIGRATION);
        migrationSai = sub(migrationSai, 1000);

        cdpDebt = getDebt(_cdpId);

        return migrationSai > cdpDebt;
    }

    function getDebt(bytes32 _cdpId) public returns (uint cdpDebt) {
        ( , , cdpDebt, ) = tubContract.cups(_cdpId);
    }

    function calcTxCost(uint _startGas, uint _currGasLeft) public view returns(uint) {
        uint gasUsed = sub(_startGas, _currGasLeft);
        uint gasPrice = tx.gasprice > MAX_GAS_PRICE ? MAX_GAS_PRICE : tx.gasprice;

        gasUsed = add(gasUsed, 180000); // add for freeEth and log

        return mul(gasPrice, gasUsed);
    }

    function isOwner(address _owner, bytes32 _cdpId) internal view returns(bool) {
        require(tubContract.lad(_cdpId) == _owner);

        return true;
    }

    receive() external payable {}

    //////////////// Admin only functions /////////////////////////


    /// @notice Adds a new bot address which will be able to call repay/boost
    /// @param _caller Bot address
    function addCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = true;
    }

    /// @notice Removes a bot address so it can't call repay/boost
    /// @param _caller Bot address
    function removeCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = false;
    }

    /// @notice Gets the Eth acumulated for the fee
    function getFee() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}
