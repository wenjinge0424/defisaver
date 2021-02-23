pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../loggers/DefisaverLogger.sol";
import "../../utils/Discount.sol";

import "../../interfaces/reflexer/IOracleRelayer.sol";
import "../../interfaces/reflexer/ITaxCollector.sol";
import "../../interfaces/reflexer/ICoinJoin.sol";

import "./RAISaverProxyHelper.sol";
import "../../utils/BotRegistry.sol";
import "../../exchangeV3/DFSExchangeCore.sol";

/// @title Implements Boost and Repay for Reflexer CDPs
contract RAISaverProxy is DFSExchangeCore, RAISaverProxyHelper {

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    bytes32 public constant ETH_COLL_TYPE = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    address public constant SAFE_ENGINE_ADDRESS = 0xCC88a9d330da1133Df3A7bD823B95e52511A6962;
    address public constant ORACLE_RELAYER_ADDRESS = 0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851;
    address public constant RAI_JOIN_ADDRESS = 0x0A5653CCa4DB1B6E265F47CAf6969e64f1CFdC45;
    address public constant TAX_COLLECTOR_ADDRESS = 0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB;
    address public constant RAI_ADDRESS = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    ISAFEEngine public constant safeEngine = ISAFEEngine(SAFE_ENGINE_ADDRESS);
    ICoinJoin public constant raiJoin = ICoinJoin(RAI_JOIN_ADDRESS);
    IOracleRelayer public constant oracleRelayer = IOracleRelayer(ORACLE_RELAYER_ADDRESS);

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Repay - draws collateral, converts to Dai and repays the debt
    /// @dev Must be called by the DSProxy contract that owns the CDP
    function repay(
        ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable {

        address managerAddr = getManagerAddr(_managerType);

        address user = getOwner(ISAFEManager(managerAddr), _cdpId);
        bytes32 ilk = ISAFEManager(managerAddr).collateralTypes(_cdpId);

        drawCollateral(managerAddr, _cdpId, _joinAddr, _exchangeData.srcAmount);

        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        (, uint daiAmount) = _sell(_exchangeData);

        daiAmount -= takeFee(_gasCost, daiAmount);

        paybackDebt(managerAddr, _cdpId, ilk, daiAmount, user);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "RAIRepay", abi.encode(_cdpId, user, _exchangeData.srcAmount, daiAmount));

    }

    /// @notice Boost - draws Dai, converts to collateral and adds to CDP
    /// @dev Must be called by the DSProxy contract that owns the CDP
    function boost(
        ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr,
        ManagerType _managerType
    ) public payable {

        address managerAddr = getManagerAddr(_managerType);

        address user = getOwner(ISAFEManager(managerAddr), _cdpId);
        bytes32 ilk = ISAFEManager(managerAddr).collateralTypes(_cdpId);

        uint daiDrawn = drawDai(managerAddr, _cdpId, ilk, _exchangeData.srcAmount);

        _exchangeData.user = user;
        _exchangeData.dfsFeeDivider = isAutomation() ? AUTOMATIC_SERVICE_FEE : MANUAL_SERVICE_FEE;
        _exchangeData.srcAmount = daiDrawn - takeFee(_gasCost, daiDrawn);
        (, uint swapedColl) = _sell(_exchangeData);

        addCollateral(managerAddr, _cdpId, _joinAddr, swapedColl);

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "RAIBoost", abi.encode(_cdpId, user, _exchangeData.srcAmount, swapedColl));
    }

    /// @notice Draws Dai from the CDP
    /// @dev If _daiAmount is bigger than max available we'll draw max
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _daiAmount Amount of Dai to draw
    function drawDai(address _managerAddr, uint _cdpId, bytes32 _ilk, uint _daiAmount) internal returns (uint) {
        uint rate = ITaxCollector(TAX_COLLECTOR_ADDRESS).taxSingle(_ilk);
        uint daiVatBalance = safeEngine.coinBalance(ISAFEManager(_managerAddr).safes(_cdpId));

        uint maxAmount = getMaxDebt(_managerAddr, _cdpId, _ilk);

        if (_daiAmount >= maxAmount) {
            _daiAmount = sub(maxAmount, 1);
        }

        ISAFEManager(_managerAddr).modifySAFECollateralization(_cdpId, int(0), normalizeDrawAmount(_daiAmount, rate, daiVatBalance));
        ISAFEManager(_managerAddr).transferInternalCoins(_cdpId, address(this), toRad(_daiAmount));

        if (safeEngine.safeRights(address(this), address(RAI_JOIN_ADDRESS)) == 0) {
            safeEngine.approveSAFEModification(RAI_JOIN_ADDRESS);
        }

        ICoinJoin(RAI_JOIN_ADDRESS).exit(address(this), _daiAmount);

        return _daiAmount;
    }

    /// @notice Adds collateral to the CDP
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _joinAddr Address of the join contract for the CDP collateral
    /// @param _amount Amount of collateral to add
    function addCollateral(address _managerAddr, uint _cdpId, address _joinAddr, uint _amount) internal {
        int convertAmount = 0;

        if (isEthJoinAddr(_joinAddr)) {
            // IBasicTokenAdapters(_joinAddr).collateral().deposit{value: _amount}();
            convertAmount = toPositiveInt(_amount);
        } else {
            convertAmount = toPositiveInt(convertTo18(_joinAddr, _amount));
        }

        ERC20(address(IBasicTokenAdapters(_joinAddr).collateral())).safeApprove(_joinAddr, _amount);

        IBasicTokenAdapters(_joinAddr).join(address(this), _amount);

        safeEngine.modifySAFECollateralization(
            ISAFEManager(_managerAddr).collateralTypes(_cdpId),
            ISAFEManager(_managerAddr).safes(_cdpId),
            address(this),
            address(this),
            convertAmount,
            0
        );

    }

    /// @notice Draws collateral and returns it to DSProxy
    /// @param _managerAddr Address of the CDP Manager
    /// @dev If _amount is bigger than max available we'll draw max
    /// @param _cdpId Id of the CDP
    /// @param _joinAddr Address of the join contract for the CDP collateral
    /// @param _amount Amount of collateral to draw
    function drawCollateral(address _managerAddr, uint _cdpId, address _joinAddr, uint _amount) internal returns (uint) {
        uint frobAmount = _amount;

        if (IBasicTokenAdapters(_joinAddr).decimals() != 18) {
            frobAmount = _amount * (10 ** (18 - IBasicTokenAdapters(_joinAddr).decimals()));
        }

        ISAFEManager(_managerAddr).modifySAFECollateralization(_cdpId, -toPositiveInt(frobAmount), 0);
        ISAFEManager(_managerAddr).transferCollateral(_cdpId, address(this), frobAmount);

        IBasicTokenAdapters(_joinAddr).exit(address(this), _amount);

        if (isEthJoinAddr(_joinAddr)) {
            // IBasicTokenAdapters(_joinAddr).gem().withdraw(_amount); // Weth -> Eth
        }

        return _amount;
    }

    /// @notice Paybacks Dai debt
    /// @param _managerAddr Address of the CDP Manager
    /// @dev If the _daiAmount is bigger than the whole debt, returns extra Dai
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _daiAmount Amount of Dai to payback
    /// @param _owner Address that owns the DSProxy that owns the CDP
    function paybackDebt(address _managerAddr, uint _cdpId, bytes32 _ilk, uint _daiAmount, address _owner) internal {
        address urn = ISAFEManager(_managerAddr).safes(_cdpId);

        uint wholeDebt = getAllDebt(SAFE_ENGINE_ADDRESS, urn, urn, _ilk);

        if (_daiAmount > wholeDebt) {
            ERC20(RAI_ADDRESS).transfer(_owner, sub(_daiAmount, wholeDebt));
            _daiAmount = wholeDebt;
        }

        if (ERC20(RAI_ADDRESS).allowance(address(this), RAI_JOIN_ADDRESS) == 0) {
            ERC20(RAI_ADDRESS).approve(RAI_JOIN_ADDRESS, uint(-1));
        }

        raiJoin.join(urn, _daiAmount);

        ISAFEManager(_managerAddr).modifySAFECollateralization(_cdpId, 0, normalizePaybackAmount(SAFE_ENGINE_ADDRESS, urn, _ilk));
    }

    /// @notice Gets the maximum amount of collateral available to draw
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @param _joinAddr Joind address of collateral
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxCollateral(address _managerAddr, uint _cdpId, bytes32 _ilk, address _joinAddr) public view returns (uint) {
        uint price = getPrice(_ilk);

        (uint collateral, uint debt) = getCdpInfo(ISAFEManager(_managerAddr), _cdpId, _ilk);

        (, uint mat) = oracleRelayer.collateralTypes(_ilk);

        uint maxCollateral = sub(collateral, (div(mul(mat, debt), price)));

        uint normalizeMaxCollateral = maxCollateral / (10 ** (18 - IBasicTokenAdapters(_joinAddr).decimals()));

        // take one percent due to precision issues
        return normalizeMaxCollateral * 99 / 100;
    }

    /// @notice Gets the maximum amount of debt available to generate
    /// @param _managerAddr Address of the CDP Manager
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    /// @dev Substracts 10 wei to aviod rounding error later on
    function getMaxDebt(address _managerAddr, uint _cdpId, bytes32 _ilk) public virtual view returns (uint) {
        uint price = getPrice(_ilk);

        (, uint mat) = oracleRelayer.collateralTypes(_ilk);
        (uint collateral, uint debt) = getCdpInfo(ISAFEManager(_managerAddr), _cdpId, _ilk);

        return sub(sub(div(mul(collateral, price), mat), debt), 10);
    }

    /// @notice Gets a price of the asset
    /// @param _ilk Ilk of the CDP
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = oracleRelayer.collateralTypes(_ilk);
        (,,uint spot,,) = safeEngine.collateralTypes(_ilk);

        return rmul(rmul(spot, oracleRelayer.redemptionPrice()), mat);
    }

    function isAutomation() internal view returns(bool) {
        return BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin);
    }

    function takeFee(uint256 _gasCost, uint _amount) internal returns(uint) {
        if (_gasCost > 0) {
            uint ethDaiPrice = getPrice(ETH_COLL_TYPE);
            uint feeAmount = rmul(_gasCost, ethDaiPrice);

            if (feeAmount > _amount / 5) {
                feeAmount = _amount / 5;
            }

            address walletAddr = _feeRecipient.getFeeAddr();

            ERC20(RAI_ADDRESS).transfer(walletAddr, feeAmount);

            return feeAmount;
        }

        return 0;
    }
}
