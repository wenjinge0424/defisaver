pragma solidity ^0.6.0;

import "../../flashloan/aave/ILendingPool.sol";
import "../../flashloan/FlashLoanLogger.sol";
import "../helpers/CompoundSaverHelper.sol";
import "../CompoundBasicProxy.sol";
import "../../auth/ProxyPermission.sol";

/// @title Opens compound positions with a leverage
contract CompoundCreateTaker is CompoundSaverHelper, CompoundBasicProxy, ProxyPermission {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_CREATE_FLASH_LOAN = 0x0D5Ec207D7B29525Cc25963347903958C98a66d3;

    // solhint-disable-next-line const-name-snakecase
    FlashLoanLogger public constant logger = FlashLoanLogger(
        0xb9303686B0EE92F92f63973EF85f3105329D345c
    );

    function openLeveragedLoan(
        uint[6] calldata _data, // amountColl, amountDebt, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external payable {
        address tokenAddr = getUnderlyingAddr(_addrData[0]);

        deposit(tokenAddr, _addrData[0], _data[0], true);

        uint maxDebt = getMaxBorrow(_addrData[1], address(this));

        if (_data[1] <= maxDebt) {
            // convert that debt and deposit back
        } else {
            uint loanAmount = (_data[1] - maxDebt);
            bytes memory paramsData = abi.encode(_data, _addrData, _callData, true, address(this));

            givePermission(COMPOUND_CREATE_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_CREATE_FLASH_LOAN, getUnderlyingAddr(_addrData[1]), loanAmount, paramsData);

            removePermission(COMPOUND_CREATE_FLASH_LOAN);

            logger.logFlashLoan("CompoundLeveragedLoan", loanAmount, _data[0], _addrData[0]);
        }
    }
}
