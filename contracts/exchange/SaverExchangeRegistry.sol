pragma solidity ^0.6.0;

import "../auth/AdminAuth.sol";

contract SaverExchangeRegistry is AdminAuth {

	mapping(address => bool) private wrappers;

	constructor() public {
		wrappers[0x5b1869D9A4C187F2EAa108f3062412ecf0526b24] = true;
		wrappers[0xCfEB869F69431e42cdB54A4F4f105C19C080A601] = true;
		wrappers[0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B] = true;
	}

	function addWrapper(address _wrapper) public onlyOwner {
		wrappers[_wrapper] = true;
	}

	function removeWrapper(address _wrapper) public onlyOwner {
		wrappers[_wrapper] = false;
	}

	function isWrapper(address _wrapper) public view returns(bool) {
		return wrappers[_wrapper];
	}
}
