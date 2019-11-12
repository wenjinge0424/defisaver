pragma solidity ^0.5.0;

import "../../DS/DSGuard.sol";
import "../migration/MigrationProxyActions.sol";
import "./Subscriptions.sol";
import "../../Monitor.sol";
import "../../constants/ConstantAddresses.sol";

/// @title Implements logic for migrating CDP to MCD cdp
contract MonitorMigrateProxy is MigrationProxyActions, ConstantAddresses {

    address payable public constant scdMcdMigration = 0x97cB5A9aBcdBE291D0CD85915fA5b08746Fe948A;
    address public constant subscriptionsContract = 0x267a8E54a6510784A168A2B4cc177e34D4f670B8;
    address public constant monitorContract = 0x32ED63E1FD1D6D3E03A174088f6E1a32daD964FC;

    enum MigrationType { WITH_MKR, WITH_CONVERSION, WITH_DEBT }

    /// @dev Called by DSProxy
    function migrateAndSubscribe(bytes32 _cdpId, uint _minRatio, MigrationType _type) external {

        Subscriptions sub = Subscriptions(subscriptionsContract);
        Monitor monitor = Monitor(monitorContract);
        DSGuard guard = getDSGuard();

        // Get and cancel old subscription
        (
         uint minRatio,
         uint maxRatio,
         uint optimalRatioBoost,
         uint optimalRatioRepay,
        ) = monitor.holders(_cdpId);

        monitor.unsubscribe(_cdpId);

        uint newCdpId;

        // Migrate
        if (_type == MigrationType.WITH_MKR) {
            newCdpId = migrate(scdMcdMigration, _cdpId);
        } else if (_type == MigrationType.WITH_CONVERSION) {
            newCdpId = migratePayFeeWithGem(scdMcdMigration, _cdpId, OTC_ADDRESS, MAKER_DAI_ADDRESS, uint(-1));
        } else if (_type == MigrationType.WITH_DEBT) {
             newCdpId = migratePayFeeWithDebt(scdMcdMigration, _cdpId, OTC_ADDRESS, uint(-1), _minRatio);
        }

        // Authorize
        guard.forbid(address(monitor), address(this), bytes4(keccak256("execute(address,bytes)")));
        guard.permit(address(sub), address(this), bytes4(keccak256("execute(address,bytes)")));

        // New Subscription
        sub.subscribe(
            newCdpId,
            uint128(minRatio),
            uint128(maxRatio),
            uint128(optimalRatioBoost),
            uint128(optimalRatioRepay)
        );
        }

    function getDSGuard() internal view returns (DSGuard) {
        DSProxy proxy = DSProxy(address(uint160(address(this))));
        DSAuth auth = DSAuth(address(proxy.authority));

        return DSGuard(address(auth));
    }
}
