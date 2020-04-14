pragma solidity ^0.5.0;

import "../aave/ILendingPool.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../mcd/maker/Vat.sol";
import "../../mcd/maker/Manager.sol";
import "../../DS/DSMath.sol";
import "../../auth/ProxyPermission.sol";

contract BridgeFlashLoanTaker is DSMath, ProxyPermission {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant cDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    address payable public constant LOAN_MOVER = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    Manager public constant manager = Manager(MANAGER_ADDRESS);

    function compound2Maker(
        uint _cdpId,
        address _joinAddr,
        address _cCollateralAddr
    ) external {
        bytes32 ilk = manager.ilks(_cdpId);
        uint debtAmount = getAllDebtCompound();

        bytes memory paramsData = abi.encode(_cdpId, _joinAddr, _cCollateralAddr, ilk, 1, address(this));

        givePermission(LOAN_MOVER);

        lendingPool.flashLoan(LOAN_MOVER, DAI_ADDRESS, debtAmount, paramsData);

        removePermission(LOAN_MOVER);
    }

    function maker2Compound(
        uint _cdpId,
        address _joinAddr,
        address _cCollateralAddr
    ) external {
        bytes32 ilk = manager.ilks(_cdpId);
        uint debtAmount = getAllDebtCDP(VAT_ADDRESS, manager.urns(_cdpId), manager.urns(_cdpId), ilk);

        bytes memory paramsData = abi.encode(_cdpId, _joinAddr, _cCollateralAddr, ilk, 2, address(this));

        givePermission(LOAN_MOVER);

        lendingPool.flashLoan(LOAN_MOVER, DAI_ADDRESS, debtAmount, paramsData);

        removePermission(LOAN_MOVER);
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
