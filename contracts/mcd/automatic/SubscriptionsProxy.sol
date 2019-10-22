pragma solidity ^0.5.0;

import "../../DS/DSGuard.sol";
import "../../DS/DSAuth.sol";
import "./Subscriptions.sol";
import "../../constants/ConstantAddresses.sol";

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract SubscriptionsProxy is ConstantAddresses {

    function subscribe(uint _cdpId, uint32 _minRatio, uint32 _maxRatio, uint32 _optimalRatioBoost, uint32 _optimalRatioRepay, address _subscriptions) public {
        DSGuard guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
        DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));

        guard.permit(_subscriptions, address(this), bytes4(keccak256("execute(address,bytes)")));

        Subscriptions(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay);
    }

    function update(uint _cdpId, uint32 _minRatio, uint32 _maxRatio, uint32 _optimalRatioBoost, uint32 _optimalRatioRepay, address _subscriptions) public {
        Subscriptions(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay);
    }

    function unsubscribe(uint _cdpId, address _subscriptions) public {
        Subscriptions(_subscriptions).unsubscribe(_cdpId);
    }
}
