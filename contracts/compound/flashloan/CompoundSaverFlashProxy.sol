pragma solidity ^0.5.0;

import "../CompoundSaverProxy.sol";
import "../../mcd/Discount.sol";

contract CompoundFlashSaverProxy is CompoundSaverProxy {

    // TODO: don't use msg.value
    function flashRepay(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        // draw max coll
        // swap max coll + loanAmount
        // payback debt
        // draw collateral for loanAmount + loanFee
    }

     function flashBoost(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData,
        uint[2] memory _flashLoanData // amount, fee
    ) public payable {
        // draw max borrow
        // swap max borrow + loanAmount
        // add collateral
        // borrow to repay loanAmount + loanFee
    }

}
