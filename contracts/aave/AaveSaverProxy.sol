pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./AaveCommonMethods.sol";
import "../utils/GasBurner.sol";
import "../interfaces/ERC20.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPool.sol";
import "../exchange/SaverExchangeCore.sol";
import "../loggers/DefisaverLogger.sol";

contract AaveSaverProxy is GasBurner, SaverExchangeCore, AaveCommonMethods {

	// TODO: change address
	address public constant DEFISAVER_LOGGER = 0xCfEB869F69431e42cdB54A4F4f105C19C080A601;

	function repay(ExchangeData memory _data, uint _gasCost) public payable burnGas(0) {

		address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
		address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
		address payable user = payable(getUserAddress());

		uint256 maxCollateral = getMaxCollateral(_data.srcAddr, address(this));
		// don't swap more than maxCollateral
		_data.srcAmount = _data.srcAmount > maxCollateral ? maxCollateral : _data.srcAmount;

		// redeem collateral
		address aTokenCollateral = ILendingPool(lendingPoolCore).getReserveATokenAddress(_data.srcAddr);
		IAToken(aTokenCollateral).redeem(_data.srcAmount);

		// swap
		(, uint256 destAmount) = _sell(_data);

		destAmount -= getFee(destAmount, user, _gasCost, _data.destAddr);

		// payback
		if (_data.destAddr == ETH_ADDR) {
			ILendingPool(lendingPool).repay{value: destAmount}(_data.destAddr, destAmount, payable(address(this)));
		} else {
			approveToken(_data.destAddr, lendingPoolCore);
			ILendingPool(lendingPool).repay(_data.destAddr, destAmount, payable(address(this)));
		}
		
		// returning to msg.sender as it is the address that actually sent 0x fee
		msg.sender.transfer(address(this).balance);

		DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveRepay", abi.encode(_data.srcAddr, _data.destAddr, _data.srcAmount, destAmount));
	}

	function boost(ExchangeData memory _data, uint _gasCost) public payable burnGas(0) {
		address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
		address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
		address payable user = payable(getUserAddress());	

		uint256 maxBorrow = getMaxBorrow(_data.srcAddr, address(this));
		_data.srcAmount = _data.srcAmount > maxBorrow ? maxBorrow : _data.srcAmount;

		// borrow amount
		ILendingPool(lendingPool).borrow(_data.srcAddr, _data.srcAmount, 1, AAVE_REFERRAL_CODE);
		_data.srcAmount -= getFee(_data.srcAmount, user, _gasCost, _data.srcAddr);

		// swap
		(, uint256 destAmount) = _sell(_data);

		if (_data.destAddr == ETH_ADDR) {
			ILendingPool(lendingPool).deposit{value: destAmount}(_data.destAddr, destAmount, AAVE_REFERRAL_CODE);
		} else {
			approveToken(_data.destAddr, lendingPoolCore);
			ILendingPool(lendingPool).deposit(_data.destAddr, destAmount, AAVE_REFERRAL_CODE);
		}

		// returning to msg.sender as it is the address that actually sent 0x fee
		msg.sender.transfer(address(this).balance);

		DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveBoost", abi.encode(_data.srcAddr, _data.destAddr, _data.srcAmount, destAmount));
	}
}