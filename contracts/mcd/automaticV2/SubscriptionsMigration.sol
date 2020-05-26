pragma solidity ^0.6.0;

import "../../auth/Auth.sol";
import "../automatic/MCDMonitorProxy.sol";
import "../automatic/ISubscriptions.sol";
import "../../utils/DSAuthorityUnsubscribe.sol";

contract SubscriptionsMigration is Auth {

	address public monitorProxyAddress = 0x93Efcf86b6a7a33aE961A7Ec6C741F49bce11DA7;
	// v1 monitor proxy
	MCDMonitorProxy public monitorProxyContract = MCDMonitorProxy(monitorProxyAddress);
	// v1 subscriptions contract
	ISubscriptions public subscriptionsContract = ISubscriptions(0x83152CAA0d344a2Fd428769529e2d490A88f4393);
	// v2 subscriptions proxy with "migrate" method
	address public subscriptionsProxyV2address = 0xd6f2125bF7FE2bc793dE7685EA7DEd8bff3917DD;
	// v2 subscriptions address (needs to be passed to migrate method)
	address public subscriptionsV2address = 0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a;
	// DSAuthorityUnsubscribe address
	// TODO: SET ADDRESS
	address public dsAuthorityUnsubscribeAddress = 0x0000000000000000000000000000000000000000;

	function migrate(uint[] memory cdps) public onlyAuthorized {

		for (uint i=0; i<cdps.length; i++) {
			bool sub;
			uint minRatio;
			uint maxRatio;
			uint optimalRepay;
			uint optimalBoost;
			address owner;

			// get data for specific cdp
			(sub, minRatio, maxRatio, optimalRepay, optimalBoost, owner,,) = subscriptionsContract.getSubscribedInfo(cdps[i]);

			// if cdp unsubbed in the meantime, just continue with others
			if (!sub) continue;

			// call migrate method on SubscriptionsProxyV2 through users DSProxy
			monitorProxyContract.callExecute(owner, subscriptionsProxyV2address, abi.encodeWithSignature("migrate(uint256,uint128,uint128,uint128,uint128,bool,bool,address)", cdps[i], minRatio, maxRatio, optimalBoost, optimalRepay, true, true, subscriptionsV2address));
		}
	}


	function removeAuthority() public onlyAuthorized {

		monitorProxyContract.callExecute(owner, dsAuthorityUnsubscribeAddress, abi.encodeWithSignature("removeAuthority(address)", monitorProxyAddress));
	}
}