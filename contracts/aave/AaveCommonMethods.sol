pragma solidity ^0.6.0;

import "../interfaces/ERC20.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPool.sol";

contract AaveCommonMethods {

	address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant AAVE_LENDING_POOL_ADDRESSES = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

	function getMaxCollateral()	public view returns (uint) {

	}
}