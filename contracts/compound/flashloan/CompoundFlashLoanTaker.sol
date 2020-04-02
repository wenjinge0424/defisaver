pragma solidity ^0.5.0;

import "../../flashloan/aave/ILendingPool.sol";
import "../CompoundSaverProxy.sol";
import "../../flashloan/FlashLoanLogger.sol";

contract CompoundFlashLoanTaker is CompoundSaverProxy {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_SAVER_FLASH_LOAN = 0x86E132932566fb7030eeF19B997C8797De13CFBD;

    // solhint-disable-next-line const-name-snakecase
    FlashLoanLogger public constant logger = FlashLoanLogger(
        0xb9303686B0EE92F92f63973EF85f3105329D345c
    );

    function repayWithLoan(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external payable {
        uint maxColl = getMaxCollateral(_addrData[0]);

        if (_data[0] <= maxColl) {
            repay(_data, _addrData, _callData);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_data[0] - maxColl);
            bytes memory paramsData = abi.encode(_data, _addrData, _callData);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[0]), loanAmount, paramsData);

            logger.logFlashLoan("CompoundFlashRepay", loanAmount, _data[0], _addrData[0]);

        }
    }

    function boostWithLoan(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external payable {
        uint maxBorrow = getMaxBorrow(_addrData[1]);

        if (_data[0] <= maxBorrow) {
            boost(_data, _addrData, _callData);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_data[0] - maxBorrow);
            bytes memory paramsData = abi.encode(_data, _addrData, _callData);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[1]), loanAmount, paramsData);

            logger.logFlashLoan("CompoundFlashBoost", loanAmount, _data[0], _addrData[1]);
        }

    }

}
