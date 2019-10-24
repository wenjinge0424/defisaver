pragma solidity ^0.5.0;

import "../../interfaces/ExchangeInterface.sol";
import "../../SaverLogger.sol";
import "../../Discount.sol";

import "../maker/Spotter.sol";
import "../maker/Jug.sol";
import "../maker/DaiJoin.sol";

import "./MCDExchange.sol";
import "./ExchangeHelper.sol";
import "./SaverProxyHelper.sol";

contract MCDSaverProxy is SaverProxyHelper, ExchangeHelper {

    // KOVAN
    address public constant VAT_ADDRESS = 0x6e6073260e1a77dFaf57D0B92c44265122Da8028;
    address public constant MANAGER_ADDRESS = 0x1Cb0d969643aF4E929b3FafA5BA82950e31316b8;
    address public constant JUG_ADDRESS = 0x3793181eBbc1a72cc08ba90087D21c7862783FA5;
    address public constant DAI_JOIN_ADDRESS = 0x61Af28390D0B3E806bBaF09104317cb5d26E215D;

    address payable public constant OASIS_TRADE = 0x8EFd472Ca15BED09D8E9D7594b94D4E42Fe62224;

    address public constant DAI_ADDRESS = 0x1f9BEAf12D8db1e50eA8a5eD53FB970462386aA0;
    address public constant SAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;

    address public constant LOGGER_ADDRESS = 0x32d0e18f988F952Eb3524aCE762042381a2c39E5;

    address public constant ETH_JOIN_ADDRESS = 0xc3AbbA566bb62c09b7f94704d8dFd9800935D3F9;

    address public constant MCD_EXCHANGE_ADDRESS = 0x2f0449f3E73B1E343ADE21d813eE03aA23bfd2e8;

    address public constant SPOTTER_ADDRESS = 0xF5cDfcE5A0b85fF06654EF35f4448E74C523c5Ac;

    address public constant DISCOUNT_ADDRESS = 0x1297c1105FEDf45E0CF6C102934f32C4EB780929;
    address payable public constant WALLET_ID = 0x54b44C6B18fc0b4A1010B21d524c338D1f8065F6;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    modifier boostCheck(uint _cdpId) {
        Manager manager = Manager(MANAGER_ADDRESS);
        bytes32 ilk = manager.ilks(_cdpId);

        uint collateralBefore;
        (collateralBefore, ) = Vat(manager.vat()).urns(ilk, manager.urns(_cdpId));

        _;

        uint collateralAfter;
        (collateralAfter, ) = Vat(manager.vat()).urns(ilk, manager.urns(_cdpId));

        require(collateralAfter > collateralBefore);
    }

    modifier repayCheck(uint _cdpId) {
        Manager manager = Manager(MANAGER_ADDRESS);
        bytes32 ilk = manager.ilks(_cdpId);

        uint beforeRatio = getRatio(manager, _cdpId, ilk);

        _;

        require(getRatio(manager, _cdpId, ilk) > beforeRatio);
    }

    function repay(uint _cdpId, address _collateralJoin, uint _collateralAmount, uint _minPrice, uint _exchangeType) external repayCheck(_cdpId) {
        Manager manager = Manager(MANAGER_ADDRESS);

        drawCollateral(manager, _cdpId, _collateralJoin, _collateralAmount);

        uint daiAmount = swap(getCollateralAddr(_collateralJoin), SAI_ADDRESS, _collateralAmount, _minPrice, _exchangeType);

        // TODO: remove only used for testing
        MCDExchange(MCD_EXCHANGE_ADDRESS).saiToDai(daiAmount);

        uint daiAfterFee = sub(daiAmount, getFee(daiAmount));

        paybackDebt(manager, _cdpId, daiAfterFee);

        SaverLogger(LOGGER_ADDRESS).LogRepay(_cdpId, msg.sender, _collateralAmount, daiAmount);
    }

    function boost(uint _cdpId, address _collateralJoin, uint _daiAmount, uint _minPrice, uint _exchangeType) external boostCheck(_cdpId) {
        Manager manager = Manager(MANAGER_ADDRESS);
        bytes32 ilk = manager.ilks(_cdpId);

        drawDai(manager, ilk, _cdpId, _daiAmount);

        uint daiAfterFee = sub(_daiAmount, getFee(_daiAmount));

        // TODO: remove only used for testing
        MCDExchange(MCD_EXCHANGE_ADDRESS).daiToSai(daiAfterFee);
        ERC20(DAI_ADDRESS).transfer(MCD_EXCHANGE_ADDRESS, ERC20(DAI_ADDRESS).balanceOf(address(this)));

        ERC20(SAI_ADDRESS).approve(OASIS_TRADE, daiAfterFee);
        //TODO: change to DAI address
        uint collateralAmount = swap(SAI_ADDRESS, getCollateralAddr(_collateralJoin), _daiAmount, _minPrice, _exchangeType);

        addCollateral(manager, _cdpId, _collateralJoin, collateralAmount);

        SaverLogger(LOGGER_ADDRESS).LogBoost(_cdpId, msg.sender, _daiAmount, collateralAmount);
    }


    function drawDai(Manager _manager, bytes32 _ilk, uint _cdpId, uint _daiAmount) internal {

        Jug(JUG_ADDRESS).drip(_ilk);

        uint maxAmount = getMaxDebt(_manager, _cdpId, _ilk);

        if (_daiAmount > maxAmount) {
            _daiAmount = sub(maxAmount, 1);
        }

        _manager.frob(_cdpId, int(0), int(_daiAmount)); // draws Dai (TODO: dai amount helper function)
        _manager.move(_cdpId, address(this), _toRad(_daiAmount)); // moves Dai from Vat to Proxy

        if (Vat(VAT_ADDRESS).can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            Vat(VAT_ADDRESS).hope(DAI_JOIN_ADDRESS);
        }

        DaiJoin(DAI_JOIN_ADDRESS).exit(address(this), _daiAmount);
    }

    function addCollateral(Manager _manager, uint _cdpId, address _collateralJoin, uint _collateralAmount) internal {
        int convertAmount = toInt(convertTo18(_collateralJoin, _collateralAmount));

        if (_collateralJoin == ETH_JOIN_ADDRESS) {
            Join(_collateralJoin).gem().deposit.value(_collateralAmount)();
            convertAmount = toInt(_collateralAmount);
        }

        Join(_collateralJoin).gem().approve(_collateralJoin, _collateralAmount);
        Join(_collateralJoin).join(address(this), _collateralAmount);

        // add to cdp
        Vat(_manager.vat()).frob(
            _manager.ilks(_cdpId),
            _manager.urns(_cdpId),
            address(this),
            address(this),
            convertAmount,
            0
        );

    }

    function drawCollateral(Manager _manager, uint _cdpId, address _collateralJoin, uint _collateralAmount) internal {
        bytes32 ilk = _manager.ilks(_cdpId);

        uint maxCollateral = getMaxCollateral(_manager, _cdpId, ilk);

        if (_collateralAmount > maxCollateral) {
            _collateralAmount = sub(maxCollateral, 1);
        }

        _manager.frob(
            _cdpId,
            address(this),
            -toInt(_collateralAmount),
            0
        );

        Join(_collateralJoin).exit(address(this), _collateralAmount);

        if (_collateralJoin == ETH_JOIN_ADDRESS) {
            Join(_collateralJoin).gem().withdraw(_collateralAmount);
        }
    }

    function paybackDebt(Manager _manager, uint _cdpId, uint _daiAmount) internal {
        address urn = _manager.urns(_cdpId);
        bytes32 ilk = _manager.ilks(_cdpId);

        DaiJoin(DAI_JOIN_ADDRESS).dai().approve(DAI_JOIN_ADDRESS, _daiAmount);

        DaiJoin(DAI_JOIN_ADDRESS).join(urn, _daiAmount);

        _manager.frob(_cdpId, 0, _getWipeDart(address(_manager.vat()), urn, ilk));
    }

    function getFee(uint _amount) internal returns (uint feeAmount) {
        uint fee = SERVICE_FEE;

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(msg.sender)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(msg.sender);
        }

        if (fee == 0) {
            feeAmount = 0;
        } else {
            feeAmount = _amount / fee;
            ERC20(DAI_ADDRESS).transfer(WALLET_ID, feeAmount);
        }
    }

    // TODO: check if valid
    function getMaxCollateral(Manager _manager, uint _cdpId, bytes32 _ilk) public view returns (uint) {
        uint collateral;
        uint debt;
        uint mat;

        uint price = getPrice(_manager, _ilk);
        (collateral, debt) = getCdpInfo(_manager, _cdpId, _ilk);

        (, mat) = Spotter(SPOTTER_ADDRESS).ilks(_ilk);

        return sub(collateral, (wdiv(wmul(mat, debt), price)));
    }

    // TODO: check if valid
    function getMaxDebt(Manager _manager, uint _cdpId, bytes32 _ilk) public view returns (uint) {
        uint price = getPrice(_manager, _ilk);
        uint collateral;
        uint debt;
        uint mat;

        (, mat) = Spotter(SPOTTER_ADDRESS).ilks(_ilk);
        (collateral, debt) = getCdpInfo(_manager, _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    function getPrice(Manager _manager, bytes32 _ilk) public view returns (uint) {
        uint mat;
        uint spot;

        uint par = Spotter(SPOTTER_ADDRESS).par();
        (, mat) = Spotter(SPOTTER_ADDRESS).ilks(_ilk);
        (,,spot,,) = Vat(_manager.vat()).ilks(_ilk);

        return rmul(rmul(spot, par), mat);
    }

    function getRatio(Manager _manager, uint _cdpId, bytes32 _ilk) public view returns (uint) {
        uint collateral;
        uint debt;

        uint price = getPrice(_manager, _ilk);

        (collateral, debt) = getCdpInfo(_manager, _cdpId, _ilk);

        return rdiv(wmul(collateral, price), debt);
    }

}
