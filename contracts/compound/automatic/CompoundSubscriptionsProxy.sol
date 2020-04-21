pragma solidity ^0.5.0;

import "../../DS/DSGuard.sol";
import "../../DS/DSAuth.sol";
import "../../constants/ConstantAddresses.sol";

contract ICompoundSubscription {
    function subscribe(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled) public;
    function unsubscribe() public;
}

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract CompoundSubscriptionsProxy is ConstantAddresses {

    address public constant MONITOR_PROXY_ADDRESS = 0x47d9f61bADEc4378842d809077A5e87B9c996898;
    address public constant COMPOUND_SUBSCRIPTION_ADDRESS = 0x47d9f61bADEc4378842d809077A5e87B9c996898;

    function subscribe(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, bool _boostEnabled) public {

        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(MONITOR_PROXY_ADDRESS, address(this), bytes4(keccak256("execute(address,bytes)")));

        ICompoundSubscription(COMPOUND_SUBSCRIPTION_ADDRESS).subscribe(
            _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    function update(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, bool _boostEnabled) public {
        ICompoundSubscription(COMPOUND_SUBSCRIPTION_ADDRESS).subscribe(_minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    function unsubscribe() public {
        ICompoundSubscription(COMPOUND_SUBSCRIPTION_ADDRESS).unsubscribe();
    }
}
