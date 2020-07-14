pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/ILendingPool.sol";
import "../../loggers/DefisaverLogger.sol";
import "../helpers/CompoundSaverHelper.sol";
import "../CompoundBasicProxy.sol";
import "../../auth/ProxyPermission.sol";
import "../../exchange/SaverExchangeCore.sol";

/// @title Opens compound positions with a leverage
contract CompoundCreateTaker is ProxyPermission {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    struct CreateInfo {
        address cCollAddress;
        address cBorrowAddress;
    }

    function openLeveragedLoan(
        CreateInfo memory _createInfo,
        SaverExchangeCore.ExchangeData memory _exchangeData,
        address payable _compoundReceiver
    ) public payable {

        uint loanAmount = _exchangeData.srcAmount;

        (
            uint[4] memory numData,
            address[5] memory addrData,
            uint8 enumData,
            bytes memory callData
        )
        = _packData(_createInfo, _exchangeData);

        bytes memory paramsData = abi.encode(numData, addrData, enumData, callData, address(this));

        givePermission(_compoundReceiver);

        lendingPool.flashLoan(_compoundReceiver, _exchangeData.srcAddr, loanAmount, paramsData);

        removePermission(_compoundReceiver);

        logger.Log(address(this), msg.sender, "CompoundLeveragedLoan",
            abi.encode(_exchangeData.srcAddr, _exchangeData.destAddr, _exchangeData.srcAmount, _exchangeData.destAmount));

    }

    function _packData(
        CreateInfo memory _createInfo,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[4] memory numData, address[5] memory addrData, uint8 enumData, bytes memory callData) {

        numData = [
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x
        ];

        addrData = [
            _createInfo.cCollAddress,
            _createInfo.cBorrowAddress,
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr
        ];

        enumData = uint8(exchangeData.exchangeType);

        callData = exchangeData.callData;

    }
}
