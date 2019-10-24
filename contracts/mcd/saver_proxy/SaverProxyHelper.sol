pragma solidity ^0.5.0;

import "../../DS/DSMath.sol";
import "../maker/Manager.sol";
import "../maker/Join.sol";
import "../maker/Vat.sol";

contract SaverProxyHelper is DSMath {
    function _toRad(uint wad) public pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }

    function convertTo18(address gemJoin, uint256 amt) internal returns (uint256 wad) {
        wad = mul(
            amt,
            10 ** (18 - Join(gemJoin).dec())
        );
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function _getWipeDart(
        address vat,
        address urn,
        bytes32 ilk
    ) internal view returns (int dart) {
        uint dai = Vat(vat).dai(urn);

        (, uint rate,,,) = Vat(vat).ilks(ilk);
        (, uint art) = Vat(vat).urns(ilk, urn);

        dart = toInt(dai / rate);
        dart = uint(dart) <= art ? - dart : - toInt(art);
    }

    function getCollateralAddr(address _joinAddr) internal returns (address) {
        return address(Join(_joinAddr).gem());
    }

    function getCdpInfo(Manager _manager, uint _cdpId, bytes32 _ilk) internal view returns (uint, uint) {
        uint collateral;
        uint debt;
        uint rate;

        (collateral, debt) = Vat(_manager.vat()).urns(_ilk, _manager.urns(_cdpId));
        (,rate,,,) = Vat(_manager.vat()).ilks(_ilk);

        return (collateral, rmul(debt, rate));
    }

    function getOwner(Manager _manager, uint _cdpId) public view returns (address) {
        return _manager.owns(_cdpId);
    }
}
