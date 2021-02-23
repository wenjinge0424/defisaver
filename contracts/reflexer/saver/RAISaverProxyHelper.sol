pragma solidity ^0.6.0;

import "../../DS/DSMath.sol";
import "../../DS/DSProxy.sol";
import "../../interfaces/reflexer/IBasicTokenAdapters.sol";
import "../../interfaces/reflexer/ISAFEManager.sol";
import "../../interfaces/reflexer/ISAFEEngine.sol";

/// @title Helper methods for RAISaverProxy
contract RAISaverProxyHelper is DSMath {

    enum ManagerType { RAI }

    /// @notice Returns a normalized debt _amount based on the current rate
    /// @param _amount Amount of dai to be normalized
    /// @param _rate Current rate of the stability fee
    /// @param _daiVatBalance Balance od Dai in the Vat for that CDP
    function normalizeDrawAmount(uint _amount, uint _rate, uint _daiVatBalance) internal pure returns (int dart) {
        if (_daiVatBalance < mul(_amount, RAY)) {
            dart = toPositiveInt(sub(mul(_amount, RAY), _daiVatBalance) / _rate);
            dart = mul(uint(dart), _rate) < mul(_amount, RAY) ? dart + 1 : dart;
        }
    }

    /// @notice Converts a number to Rad percision
    /// @param _wad The input number in wad percision
    function toRad(uint _wad) internal pure returns (uint) {
        return mul(_wad, 10 ** 27);
    }

    /// @notice Converts a number to 18 decimal percision
    /// @param _joinAddr Join address of the collateral
    /// @param _amount Number to be converted
    function convertTo18(address _joinAddr, uint256 _amount) internal view returns (uint256) {
        return mul(_amount, 10 ** (18 - IBasicTokenAdapters(_joinAddr).decimals()));
    }

    /// @notice Converts a uint to int and checks if positive
    /// @param _x Number to be converted
    function toPositiveInt(uint _x) internal pure returns (int y) {
        y = int(_x);
        require(y >= 0, "int-overflow");
    }

    /// @notice Gets Dai amount in Vat which can be added to Cdp
    /// @param _safeEngine Address of Vat contract
    /// @param _urn Urn of the Cdp
    /// @param _ilk Ilk of the Cdp
    function normalizePaybackAmount(address _safeEngine, address _urn, bytes32 _ilk) internal view returns (int amount) {
        uint dai = ISAFEEngine(_safeEngine).coinBalance(_urn);

        (, uint rate,,,) = ISAFEEngine(_safeEngine).collateralTypes(_ilk);
        (, uint art) = ISAFEEngine(_safeEngine).safes(_ilk, _urn);

        amount = toPositiveInt(dai / rate);
        amount = uint(amount) <= art ? - amount : - toPositiveInt(art);
    }

    /// @notice Gets the whole debt of the CDP
    /// @param _safeEngine Address of Vat contract
    /// @param _usr Address of the Dai holder
    /// @param _urn Urn of the Cdp
    /// @param _ilk Ilk of the Cdp
    function getAllDebt(address _safeEngine, address _usr, address _urn, bytes32 _ilk) internal view returns (uint daiAmount) {
        (, uint rate,,,) = ISAFEEngine(_safeEngine).collateralTypes(_ilk);
        (, uint art) = ISAFEEngine(_safeEngine).safes(_ilk, _urn);
        uint dai = ISAFEEngine(_safeEngine).coinBalance(_usr);

        uint rad = sub(mul(art, rate), dai);
        daiAmount = rad / RAY;

        daiAmount = mul(daiAmount, RAY) < rad ? daiAmount + 1 : daiAmount;
    }

    /// @notice Gets the token address from the Join contract
    /// @param _joinAddr Address of the Join contract
    function getCollateralAddr(address _joinAddr) internal view returns (address) {
        return address(IBasicTokenAdapters(_joinAddr).collateral());
    }

    /// @notice Checks if the join address is one of the Ether coll. types
    /// @param _joinAddr Join address to check
    function isEthJoinAddr(address _joinAddr) internal view returns (bool) {
        // if it's dai_join_addr don't check gem() it will fail
        if (_joinAddr == 0x9759A6Ac90977b93B58547b4A71c78317f391A28) return false;

        // if coll is weth it's and eth type coll
        if (address(IBasicTokenAdapters(_joinAddr).collateral()) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            return true;
        }

        return false;
    }

    /// @notice Gets CDP info (collateral, debt)
    /// @param _manager Manager contract
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getCdpInfo(ISAFEManager _manager, uint _cdpId, bytes32 _ilk) public view returns (uint, uint) {
        address vat = _manager.safeEngine();
        address urn = _manager.safes(_cdpId);

        (uint collateral, uint debt) = ISAFEEngine(vat).safes(_ilk, urn);
        (,uint rate,,,) = ISAFEEngine(vat).collateralTypes(_ilk);

        return (collateral, rmul(debt, rate));
    }

    /// @notice Address that owns the DSProxy that owns the CDP
    /// @param _manager Manager contract
    /// @param _cdpId Id of the CDP
    function getOwner(ISAFEManager _manager, uint _cdpId) public view returns (address) {
        DSProxy proxy = DSProxy(uint160(_manager.ownsSAFE(_cdpId)));

        return proxy.owner();
    }

    /// @notice Based on the manager type returns the address
    /// @param _managerType Type of vault manager to use
    function getManagerAddr(ManagerType _managerType) public pure returns (address) {
        if (_managerType == ManagerType.RAI) {
            return 0xEfe0B4cA532769a3AE758fD82E1426a03A94F185;
        }
    }
}
