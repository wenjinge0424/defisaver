pragma solidity ^0.5.0;

import "./interfaces/TubInterface.sol";
import "./DS/DSGuard.sol";
import "./DS/DSAuth.sol";
import "./Monitor.sol";
import "./constants/ConstantAddresses.sol";

/// @title MonitorProxy handles authorization and interaction with the Monitor contract
contract MonitorProxy is ConstantAddresses {

    function subscribe(bytes32 _cup, uint _minRatio, uint _maxRatio, uint _optimalRatioBoost, uint _optimalRatioRepay, uint _slippageLimit, address _monitor) public {
        DSGuard guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
        DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));

        guard.permit(_monitor, address(this), bytes4(keccak256("execute(address,bytes)")));

        Monitor(_monitor).subscribe(_cup, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _slippageLimit);
    }

    function unsubscribe(bytes32 _cup, address _monitor) public {
        Monitor(_monitor).unsubscribe(_cup);
    }
}
