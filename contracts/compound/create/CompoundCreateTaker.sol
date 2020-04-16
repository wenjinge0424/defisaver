pragma solidity ^0.5.0;

import "../CompoundSaverHelper.sol";

contract CompoundCreateTaker is CompoundSaverHelper {

    function openLeveragedLoan(
        uint[6] calldata _data, // amountColl, amountDebt, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external payable {
        address tokenAddr = getUnderlyingAddr(_addrData[0]);

        // deposit(tokenAddr, _addrData[0], _data[0], true);

        // draw max debt
        // if debt enough, convert that debt and deposit
        // if not, FL and convert that whole amount and desposit + return the loan
    }

    function openLoan() external payable {

    }



}
