pragma solidity ^0.5.0;

import "../../DS/DSGuard.sol";
import "../../DS/DSProxy.sol";
import "../migration/MigrationProxyActions.sol";
import "../../Monitor.sol";
import "../../constants/ConstantAddresses.sol";

contract SubscriptionsInterface {
    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay) external {}
}

/// @title Implements logic for migrating CDP to MCD cdp
contract MonitorMigrateProxy is MigrationProxyActions, ConstantAddresses {

    enum MigrationType { WITH_MKR, WITH_CONVERSION, WITH_DEBT }

    /// @dev Called by DSProxy
    function migrateAndSubscribe(bytes32 _cdpId, uint _minRatio, MigrationType _type) external {

        SubscriptionsInterface sub = SubscriptionsInterface(SUBSCRIPTION_ADDRESS);
        Monitor monitor = Monitor(MONITOR_ADDRESS);
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
            newCdpId = migrate(SCD_MCD_MIGRATION, _cdpId);
        } else if (_type == MigrationType.WITH_CONVERSION) {
            newCdpId = migratePayFeeWithGem(SCD_MCD_MIGRATION, _cdpId, OTC_ADDRESS, MAKER_DAI_ADDRESS, uint(-1));
        } else if (_type == MigrationType.WITH_DEBT) {
             newCdpId = migratePayFeeWithDebt(SCD_MCD_MIGRATION, _cdpId, OTC_ADDRESS, uint(-1), _minRatio);
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
