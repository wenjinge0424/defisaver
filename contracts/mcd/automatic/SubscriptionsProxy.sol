pragma solidity ^0.5.0;

import "../../DS/DSGuard.sol";
import "../../DS/DSAuth.sol";
import "../../constants/ConstantAddresses.sol";

contract Subscriptions {
    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay) external {}
    function unsubscribe(uint _cdpId) external {}
}

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract SubscriptionsProxy is ConstantAddresses {

    address public constant MONITOR_PROXY_ADDRESS = 0xE7F2f21a65ad615329cA1328aBCe421D608d4a60;

    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, address _subscriptions) public {
        DSGuard guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
        DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));

        guard.permit(MONITOR_PROXY_ADDRESS, address(this), bytes4(keccak256("execute(address,bytes)")));

        Subscriptions(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay);
    }

    function update(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, address _subscriptions) public {
        Subscriptions(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay);
    }

    function unsubscribe(uint _cdpId, address _subscriptions) public {
        Subscriptions(_subscriptions).unsubscribe(_cdpId);

        DSGuard guard = DSGuard(address(DSAuth(address(this)).authority));
        guard.forbid(MONITOR_PROXY_ADDRESS, address(this), bytes4(keccak256("execute(address,bytes)")));
    }
}
