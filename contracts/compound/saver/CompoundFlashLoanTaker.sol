pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../interfaces/ILendingPool.sol";
import "./CompoundSaverProxy.sol";
import "../../loggers/FlashLoanLogger.sol";
import "../../auth/ProxyPermission.sol";

/// @title Entry point for the FL Repay Boosts, called by DSProxy
contract CompoundFlashLoanTaker is CompoundSaverProxy, ProxyPermission, GasBurner {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_SAVER_FLASH_LOAN = 0xFcCeD5E997E7fb1D0594518D3eD57245bB8ed17E;

    // solhint-disable-next-line const-name-snakecase
    FlashLoanLogger public constant logger = FlashLoanLogger(
        0xb9303686B0EE92F92f63973EF85f3105329D345c
    );

    /// @notice Repays the position with it's own fund or with FL if needed
    /// @param _exData Exchange data
    /// @param _addrData cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _gasCost Gas cost for specific transaction
    function repayWithLoan(
        ExchangeData memory _exData,
        address[2] memory _addrData, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable burnGas(25) {
        uint maxColl = getMaxCollateral(_addrData[0], address(this));

        if (_exData.srcAmount <= maxColl) {
            repay(_exData, _addrData, _gasCost);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_exData.srcAmount - maxColl);
            bytes memory encoded = packExchangeData(_exData);
            bytes memory paramsData = abi.encode(encoded, _addrData, _gasCost, true, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[0]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.logFlashLoan("CompoundFlashRepay", loanAmount, _exData.srcAmount, _addrData[0]);
        }
    }

    /// @notice Boosts the position with it's own fund or with FL if needed
    /// @param _exData Exchange data
    /// @param _addrData cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _gasCost Gas cost for specific transaction
    function boostWithLoan(
        ExchangeData memory _exData,
        address[2] memory _addrData, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable burnGas(20) {
        uint maxBorrow = getMaxBorrow(_addrData[1], address(this));

        if (_exData.srcAmount <= maxBorrow) {
            boost(_exData, _addrData, _gasCost);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_exData.srcAmount - maxBorrow);
            bytes memory paramsData = abi.encode(packExchangeData(_exData), _addrData, _gasCost, false, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[1]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.logFlashLoan("CompoundFlashBoost", loanAmount, _exData.srcAmount, _addrData[1]);
        }

    }
}
