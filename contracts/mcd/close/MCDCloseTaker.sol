pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../constants/ConstantAddresses.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ILendingPool.sol";
import "../../exchange/SaverExchangeCore.sol";


abstract contract IMCDSubscriptions {
    function unsubscribe(uint256 _cdpId) external virtual ;

    function subscribersPos(uint256 _cdpId) external virtual returns (uint256, bool);
}


contract MCDCloseTaker is ConstantAddresses, MCDSaverProxyHelper {

    address payable public constant MCD_CLOSE_FLASH_LOAN = 0xfCF3e72445D105c38C0fDC1a0687BDEeb8947a93;

    address public constant SUBSCRIPTION_ADDRESS_NEW = 0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    // solhint-disable-next-line const-name-snakecase
    Manager public constant manager = Manager(MANAGER_ADDRESS);
    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(DEFISAVER_LOGGER);

    struct CloseData {
        uint cdpId;
        address joinAddr;
        uint collAmount;
        uint daiAmount;
        uint minAccepted;
        bool wholeDebt;
        bool toDai;
    }

    Vat public constant vat = Vat(VAT_ADDRESS);
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

    // TODO: add exit to dai
    function closeWithLoan(
        CloseData memory _closeData,
        SaverExchangeCore.ExchangeData memory _exchangeData
    ) public payable {
        MCD_CLOSE_FLASH_LOAN.transfer(msg.value); // 0x fee

        if (_closeData.wholeDebt) {
            _closeData.daiAmount = getAllDebt(
                VAT_ADDRESS,
                manager.urns(_closeData.cdpId),
                manager.urns(_closeData.cdpId),
                manager.ilks(_closeData.cdpId)
            );

            // TODO: max coll amount
        }

        manager.cdpAllow(_closeData.cdpId, MCD_CLOSE_FLASH_LOAN, 1);

        (uint[8] memory numData, address[5] memory addrData, bytes memory callData)
                                            = _packData(_closeData, _exchangeData);
        bytes memory paramsData = abi.encode(numData, addrData, callData, address(this), _closeData.toDai);

        lendingPool.flashLoan(MCD_CLOSE_FLASH_LOAN, DAI_ADDRESS, _closeData.daiAmount, paramsData);

        manager.cdpAllow(_closeData.cdpId, MCD_CLOSE_FLASH_LOAN, 0);

        // If sub. to automatic protection unsubscribe
        unsubscribe(SUBSCRIPTION_ADDRESS, _closeData.cdpId);
        unsubscribe(SUBSCRIPTION_ADDRESS_NEW, _closeData.cdpId);

        // TODO: check what to log
        logger.Log(address(this), msg.sender, "MCDClose", abi.encode(_closeData.cdpId, _closeData.daiAmount, msg.sender));
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getMaxDebt(uint256 _cdpId, bytes32 _ilk) public view returns (uint256) {
        uint256 price = getPrice(_ilk);

        (, uint256 mat) = spotter.ilks(_ilk);
        (uint256 collateral, uint256 debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint256) {
        (, uint256 mat) = spotter.ilks(_ilk);
        (, , uint256 spot, , ) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    function unsubscribe(address _subContract, uint _cdpId) internal {
        (, bool isSubscribed) = IMCDSubscriptions(_subContract).subscribersPos(_cdpId);

        if (isSubscribed) {
            IMCDSubscriptions(_subContract).unsubscribe(_cdpId);
        }
    }

    function _packData(
        CloseData memory _closeData,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[8] memory numData, address[5] memory addrData, bytes memory callData) {

        numData = [
            _closeData.cdpId,
            _closeData.collAmount,
            _closeData.daiAmount,
            _closeData.minAccepted,
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x
        ];

        addrData = [
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr,
            exchangeData.wrapper,
            _closeData.joinAddr
        ];

        callData = exchangeData.callData;
    }

}
