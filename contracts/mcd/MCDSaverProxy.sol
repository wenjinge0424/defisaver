pragma solidity ^0.5.0;

import "../DS/DSMath.sol";
import "./OasisTrade.sol";

contract ManagerInterface {
    function cdpCan(address, uint, address) public view returns (uint);
    function ilks(uint) public view returns (bytes32);
    function owns(uint) public view returns (address);
    function urns(uint) public view returns (address);
    function vat() public view returns (address);
    function open(bytes32) public returns (uint);
    function give(uint, address) public;
    function cdpAllow(uint, address, uint) public;
    function urnAllow(address, uint) public;
    function frob(uint, int, int) public;
    function frob(uint, address, int, int) public;
    function flux(uint, address, uint) public;
    function move(uint, address, uint) public;
    function exit(address, uint, address, uint) public;
    function quit(uint, address) public;
    function enter(address, uint) public;
    function shift(uint, uint) public;
}

contract GemLike {
    function approve(address, uint) public;
    function transfer(address, uint) public;
    function transferFrom(address, address, uint) public;
    function deposit() public payable;
    function withdraw(uint) public;
}

contract VatInterface {
    function can(address, address) public view returns (uint);
    function ilks(bytes32) public view returns (uint, uint, uint, uint, uint);
    function dai(address) public view returns (uint);
    function urns(bytes32, address) public view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) public;
    function hope(address) public;
    function move(address, address, uint) public;
}

contract JugInterface {
    function drip(bytes32) public;
}

contract GemInterface {
    function dec() public returns (uint);
    function gem() public returns (GemInterface);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract DaiJoinInterface {
    function vat() public returns (VatInterface);
    function dai() public returns (GemInterface);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract GemJoinLike {
    function dec() public returns (uint);
    function gem() public returns (GemLike);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract SaverProxyHelper is DSMath {
    function _toRad(uint wad) public pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }

    function convertTo18(address gemJoin, uint256 amt) internal returns (uint256 wad) {
        wad = mul(
            amt,
            10 ** (18 - GemJoinLike(gemJoin).dec())
        );
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }
}

//TODO: all methods public for testing purposes
contract MCDSaverProxy is SaverProxyHelper {

    // KOVAN
    address public constant VAT_ADDRESS = 0x6e6073260e1a77dFaf57D0B92c44265122Da8028;
    address public constant MANAGER_ADDRESS = 0x1Cb0d969643aF4E929b3FafA5BA82950e31316b8;
    address public constant JUG_ADDRESS = 0x3793181eBbc1a72cc08ba90087D21c7862783FA5;
    address public constant DAI_JOIN_ADDRESS = 0x61Af28390D0B3E806bBaF09104317cb5d26E215D;

    address payable public constant OASIS_TRADE = 0xcde92542190B49da6Eb0385bC19Cb7eb0aA8c7EC;

    address public constant DAI_ADDRESS = 0x1f9BEAf12D8db1e50eA8a5eD53FB970462386aA0;

    address public constant ETH_JOIN_ADDRESS = 0xc3AbbA566bb62c09b7f94704d8dFd9800935D3F9;

    function repay(uint _cdpId, address _collateralType, uint _collateralAmount) public {
        // check slippage

        ManagerInterface manager = ManagerInterface(MANAGER_ADDRESS);

        _drawCollateral(manager, _cdpId, _collateralAmount);

        // Exchange Collateral -> Dai

        uint daiAmount = 0;

        _paybackDebt(manager, _cdpId, daiAmount);

        // ratio check

        // logs
    }

    function boost(uint _cdpId, address _collateralJoin, uint _daiAmount) public {
        // check slippage

        ManagerInterface manager = ManagerInterface(MANAGER_ADDRESS);

        _drawDai(manager, _cdpId, _daiAmount);

        address collateralAddr = address(GemJoinLike(_collateralJoin).gem());

        ERC20(collateralAddr).approve(OASIS_TRADE, _daiAmount);
        uint collateralAmount = OasisTrade(OASIS_TRADE).swap(DAI_ADDRESS, collateralAddr, _daiAmount);

        _addCollateral(manager, _cdpId, _collateralJoin, collateralAmount);

        // ratio check

        // logs

    }


    function _drawDai(ManagerInterface _manager, uint _cdpId, uint _daiAmount) public {
        bytes32 ilk = _manager.ilks(_cdpId);

        // Update stability fee
        JugInterface(JUG_ADDRESS).drip(ilk);

        _manager.frob(_cdpId, int(0), int(_daiAmount)); // draws Dai (TODO: dai amount helper function)
        _manager.move(_cdpId, address(this), _toRad(_daiAmount)); // moves Dai from Vat to Proxy

        if (VatInterface(VAT_ADDRESS).can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            VatInterface(VAT_ADDRESS).hope(DAI_JOIN_ADDRESS);
        }

        DaiJoinInterface(DAI_JOIN_ADDRESS).exit(address(this), _daiAmount);
    }

    function _addCollateral(ManagerInterface _manager, uint _cdpId, address _collateralJoin, uint _collateralAmount) public {
        // eth -> weth
        int convertAmount = toInt(convertTo18(_collateralJoin, _collateralAmount));

        if (_collateralJoin == ETH_JOIN_ADDRESS) {
            GemJoinLike(_collateralJoin).gem().deposit.value(_collateralAmount)();
            convertAmount = toInt(_collateralAmount);
        }

        GemJoinLike(_collateralJoin).gem().approve(address(_collateralJoin), _collateralAmount);
        GemJoinLike(_collateralJoin).join(_manager.urns(_cdpId), _collateralAmount);

        // add to cdp
        VatInterface(_manager.vat()).frob(
            _manager.ilks(_cdpId),
            _manager.urns(_cdpId),
            address(this),
            address(this),
            convertAmount,
            0
        );

    }

    function _drawCollateral(ManagerInterface _manager, uint _cdpId, uint _collateralAmount) public {

    }

    function _paybackDebt(ManagerInterface _manager, uint _cdpId, uint _daiAmount) public {

    }

    function getRatio() public returns (uint) {

    }

}
