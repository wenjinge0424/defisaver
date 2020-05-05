pragma solidity ^0.6.0;

import "../../DS/DSGuard.sol";
import "../../DS/DSAuth.sol";
import "../../constants/ConstantAddresses.sol";
import "./AutomaticMigration.sol";

contract AutomaticMigrationProxy is ConstantAddresses {

    function subscribe(bytes32 _cdpId, address payable _automaticMigration, AutomaticMigration.MigrationType _type) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(_automaticMigration, address(this), bytes4(keccak256("execute(address,bytes)")));

        AutomaticMigration(_automaticMigration).subscribe(_cdpId, _type);
    }

    function unsubscribe(bytes32 _cdpId, address payable _automaticMigration) public {
        AutomaticMigration(_automaticMigration).unsubscribe(_cdpId);
    }
}
