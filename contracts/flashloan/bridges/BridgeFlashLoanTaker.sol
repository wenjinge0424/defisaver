pragma solidity ^0.6.0;

import "../aave/ILendingPool.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../mcd/maker/Vat.sol";
import "../../mcd/maker/Manager.sol";
import "../../DS/DSMath.sol";
import "../../auth/ProxyPermission.sol";
import "../FlashLoanLogger.sol";


contract BridgeFlashLoanTaker is DSMath, ProxyPermission {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant cDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    address payable public constant LOAN_MOVER = 0x1ccd1b13b7473Cdcc9b1b858CB813de95b465E79;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    Manager public constant manager = Manager(MANAGER_ADDRESS);

    // solhint-disable-next-line const-name-snakecase
    FlashLoanLogger public constant logger = FlashLoanLogger(
        0xb9303686B0EE92F92f63973EF85f3105329D345c
    );

    function compound2Maker(
        uint[3] calldata amountData, // [cdpId, collAmount, debtAmount]
        address _joinAddr,
        address _cCollateralAddr
    ) external {
        bytes32 ilk = manager.ilks(amountData[0]);
        uint debtAmount = getAllDebtCompound();

        bytes memory paramsData = abi.encode(amountData, _joinAddr, _cCollateralAddr, ilk, uint8(1), address(this));

        givePermission(LOAN_MOVER);

        lendingPool.flashLoan(LOAN_MOVER, DAI_ADDRESS, debtAmount, paramsData);

        removePermission(LOAN_MOVER);

        logger.logFlashLoan("compound2Maker", debtAmount, amountData[0], DAI_ADDRESS);
    }

    function maker2Compound(
        uint[3] calldata amountData, // [cdpId, collAmount, debtAmount]
        address _joinAddr,
        address _cCollateralAddr
    ) external {
        bytes32 ilk = manager.ilks(amountData[0]);
        uint wholeDebtAmount = getAllDebtCDP(VAT_ADDRESS, manager.urns(amountData[0]), manager.urns(amountData[0]), ilk);

        bytes memory paramsData = abi.encode(amountData, _joinAddr, _cCollateralAddr, ilk, uint8(2), address(this));

        givePermission(LOAN_MOVER);

        lendingPool.flashLoan(LOAN_MOVER, DAI_ADDRESS, wholeDebtAmount, paramsData);

        removePermission(LOAN_MOVER);

        logger.logFlashLoan("maker2Compound", wholeDebtAmount, amountData[0], DAI_ADDRESS);
    }

    function getAllDebtCDP(address _vat, address _usr, address _urn, bytes32 _ilk) internal view returns (uint daiAmount) {
        (, uint rate,,,) = Vat(_vat).ilks(_ilk);
        (, uint art) = Vat(_vat).urns(_ilk, _urn);
        uint dai = Vat(_vat).dai(_usr);

        uint rad = sub(mul(art, rate), dai);
        daiAmount = rad / RAY;

        daiAmount = mul(daiAmount, RAY) < rad ? daiAmount + 1 : daiAmount;
    }

    function getAllDebtCompound() internal returns (uint daiAmount) {
        daiAmount = CTokenInterface(cDAI_ADDRESS).borrowBalanceCurrent(address(this));
    }
}
