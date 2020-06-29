pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ILendingPool.sol";
import "../interfaces/CTokenInterface.sol";
import "../interfaces/ILoanShifter.sol";
import "../interfaces/DSProxyInterface.sol";
import "../mcd/maker/Vat.sol";
import "../mcd/maker/Manager.sol";
import "../auth/AdminAuth.sol";
import "../auth/ProxyPermission.sol";
import "../loggers/FlashLoanLogger.sol";
import "../utils/ExchangeDataParser.sol";
import "../exchange/SaverExchangeCore.sol";

contract LoanShifterTaker is AdminAuth, ProxyPermission {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant cDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    address payable public constant LOAN_MOVER = 0x1ccd1b13b7473Cdcc9b1b858CB813de95b465E79;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    Manager public constant manager = Manager(MANAGER_ADDRESS);

    enum Protocols { MCD, COMPOUND, AAVE }

    struct LoanShiftData {
        Protocols fromProtocol;
        Protocols toProtocol;
        bool wholeDebt;
        uint collAmount;
        uint debtAmount;
        address addrLoan1;
        address addrLoan2;
        uint id1;
        uint id2;
    }

    mapping (Protocols => address) public contractAddresses;

    /// @notice Moves a Loan from one protocol to another, without changing the assets
    function moveLoan(
        LoanShiftData memory _loanShift,
        SaverExchangeCore.ExchangeData memory _exchangeData
    ) public {
        if (isSameTypeVaults(_loanShift)) {
            forkVault(_loanShift);
            return;
        }

        callCloseAndOpen(_loanShift, _exchangeData);
    }

    function callCloseAndOpen(
        LoanShiftData memory _loanShift,
        SaverExchangeCore.ExchangeData memory _exchangeData
    ) internal {
        address protoAddr = getProtocolAddr(_loanShift.fromProtocol);

        uint loanAmount = _loanShift.debtAmount;

        if (_loanShift.wholeDebt) {
            loanAmount = ILoanShifter(protoAddr).getLoanAmount(_loanShift.id1, _loanShift.addrLoan1);
        }

        (
            uint[8] memory numData,
            address[5] memory addrData,
            uint8[3] memory enumData,
            bytes memory callData
        )
        = packData(_loanShift, _exchangeData);

        // encode data
        bytes memory paramsData = abi.encode(numData, addrData, enumData, callData, address(this));

        // call FL
        givePermission(LOAN_MOVER);

        // TODO: DAI_ADDRESS
        lendingPool.flashLoan(LOAN_MOVER, DAI_ADDRESS, loanAmount, paramsData);

        removePermission(LOAN_MOVER);
    }

    function getProtocolAddr(Protocols _proto) public view returns (address) {
        return contractAddresses[_proto];
    }

    function forkVault(LoanShiftData memory _loanShift) internal {
        // Create new Vault to move to
        if (_loanShift.id2 == 0) {
            _loanShift.id2 = manager.open(manager.ilks(_loanShift.id1), address(this));
        }

        if (_loanShift.wholeDebt) {
            manager.shift(_loanShift.id1, _loanShift.id2);
        } else {
            Vat(VAT_ADDRESS).fork(
                manager.ilks(_loanShift.id1),
                manager.urns(_loanShift.id1),
                manager.urns(_loanShift.id2),
                int(_loanShift.collAmount),
                int(_loanShift.debtAmount)
            );
        }
    }

    function isSameTypeVaults(LoanShiftData memory _loanShift) internal pure returns (bool) {
        return _loanShift.fromProtocol == Protocols.MCD && _loanShift.toProtocol == Protocols.MCD
                && _loanShift.addrLoan1 == _loanShift.addrLoan2;
    }

    function addProtocol(uint8 _protoType, address _protoAddr) public onlyOwner {
        contractAddresses[Protocols(_protoType)] = _protoAddr;
    }

    function packData(
        LoanShiftData memory _loanShift,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[8] memory numData, address[5] memory addrData, uint8[3] memory enumData, bytes memory callData) {

        numData = [
            _loanShift.collAmount,
            _loanShift.debtAmount,
            _loanShift.id1,
            _loanShift.id2,
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x
        ];

        addrData = [
            _loanShift.addrLoan1,
            _loanShift.addrLoan2,
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr
        ];

        enumData = [
            uint8(_loanShift.fromProtocol),
            uint8(_loanShift.toProtocol),
            uint8(exchangeData.exchangeType)
        ];

        callData = exchangeData.callData;
    }

}
