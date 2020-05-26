pragma solidity ^0.6.0;

import "../DS/DSAuth.sol";
import "../DS/DSGuard.sol";

contract DSAuthorityUnsubscribe {

    function removeAuthority(address _address) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        guard.forbid(_address, address(this), bytes4(keccak256("execute(address,bytes)")));
    }
}
