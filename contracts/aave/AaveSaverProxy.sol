pragma solidity ^0.6.0;

import "../utils/GasBurner.sol";
import "../interfaces/ERC20.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPool.sol";
import "../exchange/SaverExchangeCore.sol";
import "./AaveCommonMethods.sol";

contract AaveSaverProxy is GasBurner, SaverExchangeCore, AaveCommonMethods {

	
}