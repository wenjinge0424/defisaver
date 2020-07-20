pragma solidity ^0.6.0;

import "../auth/AdminAuth.sol";

contract SaverExchangeRegistry is AdminAuth {

	mapping(address => bool) private wrappers;

	constructor() public {
		wrappers[0x3d1D4D6Bb405b2366434cb7387803c7B662b8d71] = true;
		wrappers[0xFF92ADA50cDC8009686867b4a470C8769bEdB22d] = true;
		wrappers[0x9C499376B41A91349Ff93F99462a65962653e104] = true;
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