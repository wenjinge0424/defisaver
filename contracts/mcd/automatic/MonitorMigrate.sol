pragma solidity ^0.5.0;

import "../../DS/DSGuard.sol";
import "../migration/MigrationProxyActions.sol";
import "./Subscriptions.sol";
import "../../Monitor.sol";

contract MonitorMigrate is MigrationProxyActions {

    address payable public scdMcdMigration = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public subscriptionsContract = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public monitorContract = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;

    struct CdpHolder {
        uint minRatio;
        uint maxRatio;
        uint optimalRatioBoost;
        uint optimalRatioRepay;
        address owner;
    }

    /// @dev Called by DSProxy
    function migrateAndSubscribe(bytes32 _cdpId) external {

        Subscriptions sub = Subscriptions(subscriptionsContract);
        Monitor monitor = Monitor(monitorContract);
        DSGuard guard = getDSGuard();

        // Get and cancel old subscription
        (uint minRatio,
         uint maxRatio,
         uint optimalBoost,
         uint optimalRepay,
         ) = monitor.holders(_cdpId);

         monitor.unsubscribe(_cdpId);

        // Migrate
        uint newCdpId = migrate(scdMcdMigration, _cdpId);

        // Authorize
        guard.forbid(address(monitor), address(this), bytes4(keccak256("execute(address,bytes)")));
        guard.permit(address(sub), address(this), bytes4(keccak256("execute(address,bytes)")));

        // New Subscription
        sub.subscribe(
            newCdpId,
            uint128(minRatio),
            uint128(maxRatio),
            uint128(optimalBoost),
            uint128(optimalRepay)
        );
        }

    function getDSGuard() internal view returns (DSGuard) {
        DSProxy proxy = DSProxy(address(uint160(address(this))));
        DSAuth auth = DSAuth(address(proxy.authority));

        return DSGuard(address(auth));
    }
}
