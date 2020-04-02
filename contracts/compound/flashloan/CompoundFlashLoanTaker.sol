pragma solidity ^0.5.0;

import "../../flashloan/aave/ILendingPool.sol";
import "../CompoundSaverProxy.sol";

contract CompoundFlashLoanTaker is CompoundSaverProxy {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    function repayWithLoan(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external {
        uint maxColl = getMaxCollateral(_addrData[0]);

        if (_data[0] <= maxColl) {
            repay(_data, _addrData, _callData);
        } else {
            // FL logic
        }
    }

    function boostWithLoan(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external {
        uint maxBorrow = getMaxBorrow(_addrData[1]);

        if (_data[0] <= maxBorrow) {
            boost(_data, _addrData, _callData);
        } else {
            // FL logic
        }

    }

}
