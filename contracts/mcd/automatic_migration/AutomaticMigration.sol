pragma solidity ^0.5.0;

import "../migration/SaiTubLike.sol";
import "../maker/ScdMcdMigration.sol";
import "../../constants/ConstantAddresses.sol";
import "../migration/MigrationProxyActions.sol";
import "../maker/Manager.sol";
import "../maker/Join.sol";

contract AutomaticMigration is ConstantAddresses, MigrationProxyActions {

    enum MigrationType { WITH_MKR, WITH_CONVERSION, WITH_DEBT }

    bytes32 SAI_ILK = 0x5341490000000000000000000000000000000000000000000000000000000000;

    uint MAX_GAS_PRICE = 50000000000;

    struct Subscription {
        bytes32 cdpId;
        address owner;
        MigrationType migType;
    }

    address public owner;
    mapping (address => bool) public approvedCallers;
    mapping (bytes32 => Subscription) public subscribers;

    ScdMcdMigration public migrationContract = ScdMcdMigration(SCD_MCD_MIGRATION);
    SaiTubLike public tubContract = SaiTubLike(TUB_ADDRESS);
    Vat public vat = Vat(VAT_ADDRESS);
    Manager public manager = Manager(MANAGER_ADDRESS);

    modifier isApprovedCaller(bytes32 _cdpId) {
        require(approvedCallers[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    event Subscribed(address indexed owner, bytes32 cdpId);
    event Unsubscribed(address indexed owner, bytes32 cdpId);
    event Migrated(bytes32 indexed oldCdp, uint indexed newCdp, address owner, uint timestamp);

    constructor() public {
        owner = msg.sender;
    }

    function subscribe(bytes32 _cdpId, MigrationType _type) external {
        require(subscribers[_cdpId].owner == address(0x0));

        subscribers[_cdpId] = Subscription({
            cdpId: _cdpId,
            owner: msg.sender,
            migType: _type
        });

        emit Subscribed(msg.sender, _cdpId);
    }

    function unsubscribe(bytes32 _cdpId) external {
        require(subscribers[_cdpId].owner != address(0x0));
        require(subscribers[_cdpId].owner == msg.sender);

        delete subscribers[_cdpId];

        emit Unsubscribed(msg.sender, _cdpId);
    }

    function migrateFor(bytes32 _cdpId) external isApprovedCaller(_cdpId) {
        uint256 startGas = gasleft();

        require(subscribers[_cdpId].cdpId == _cdpId);

        require(hasEnoughLiquidity(_cdpId));

        uint newCdpId;

        MigrationType migType = subscribers[_cdpId].migType;

        if (migType == MigrationType.WITH_MKR) {
            newCdpId = migrate(SCD_MCD_MIGRATION, _cdpId);
        } else if (migType == MigrationType.WITH_CONVERSION) {
            newCdpId = migratePayFeeWithGem(SCD_MCD_MIGRATION, _cdpId, OTC_ADDRESS, MAKER_DAI_ADDRESS, uint(-1));
        } else if (migType == MigrationType.WITH_DEBT) {
             newCdpId = migratePayFeeWithDebt(SCD_MCD_MIGRATION, _cdpId, OTC_ADDRESS, uint(-1), 0);
        }

        drawCollateral(newCdpId, calcTxCost(startGas));

        emit Migrated(_cdpId, newCdpId, subscribers[_cdpId].owner, block.timestamp);
    }

    function hasEnoughLiquidity(bytes32 _cdpId) public returns (bool) {
        uint migrationSai;
        uint cdpDebt;

        (, migrationSai) = vat.urns(SAI_ILK, SCD_MCD_MIGRATION);
        migrationSai = sub(migrationSai, 1000);

        ( , , cdpDebt, ) = tubContract.cups(_cdpId);

        return migrationSai > cdpDebt;
    }

    function drawCollateral(uint _cdpId, uint _amount) internal {

        manager.frob(_cdpId, -int(_amount), 0);
        manager.flux(_cdpId, address(this), _amount);

        Join(ETH_JOIN_ADDRESS).exit(address(this), _amount);

        Join(ETH_JOIN_ADDRESS).gem().withdraw(_amount); // Weth -> Eth

    }

    function calcTxCost(uint _startGas) public view returns(uint) {
        uint gasUsed = sub(_startGas, gasleft());
        uint gasPrice = tx.gasprice > MAX_GAS_PRICE ? MAX_GAS_PRICE : tx.gasprice;

        return mul(gasPrice, gasUsed);
    }


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
}
