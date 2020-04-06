pragma solidity ^0.5.0;

import "../../flashloan/aave/ILendingPool.sol";
import "../CompoundSaverProxy.sol";
import "../../flashloan/FlashLoanLogger.sol";
import "../../DS/DSGuard.sol";
import "../../DS/DSAuth.sol";

contract CompoundFlashLoanTaker is CompoundSaverProxy {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_SAVER_FLASH_LOAN = 0x0D5Ec207D7B29525Cc25963347903958C98a66d3;

    address public constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

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
            bytes memory paramsData = abi.encode(_data, _addrData, _callData, true, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[0]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

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
            bytes memory paramsData = abi.encode(_data, _addrData, _callData, false, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[1]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.logFlashLoan("CompoundFlashBoost", loanAmount, _data[0], _addrData[1]);
        }

    }

    function givePermission(address _contractAddr) internal {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }

    function removePermission(address _contractAddr) internal {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        guard.forbid(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }

}
