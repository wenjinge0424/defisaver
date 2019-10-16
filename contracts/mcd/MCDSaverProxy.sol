pragma solidity ^0.5.0;

import "../DS/DSMath.sol";
import "./OasisTrade.sol";
import "./MCDExchange.sol";
import "../SaverLogger.sol";

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

contract DaiJoinLike {
    function vat() public returns (VatInterface);
    function dai() public returns (GemLike);
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

    function _getWipeDart(
        address vat,
        address urn,
        bytes32 ilk
    ) internal view returns (int dart) {
        uint dai = VatInterface(vat).dai(urn);

        (, uint rate,,,) = VatInterface(vat).ilks(ilk);
        (, uint art) = VatInterface(vat).urns(ilk, urn);

        dart = toInt(dai / rate);
        dart = uint(dart) <= art ? - dart : - toInt(art);
    }
}

//TODO: all methods public for testing purposes
contract MCDSaverProxy is SaverProxyHelper {

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

    function repay(uint _cdpId, address _collateralJoin, uint _collateralAmount) public {
        //TODO: check slippage

        ManagerInterface manager = ManagerInterface(MANAGER_ADDRESS);

        _drawCollateral(manager, _cdpId, _collateralJoin, _collateralAmount);

        address collateralAddr = address(GemJoinLike(_collateralJoin).gem());

        uint daiAmount = OasisTrade(OASIS_TRADE).swap.value(_collateralAmount)(collateralAddr, SAI_ADDRESS, _collateralAmount);

        // TODO: remove only used for testing
        MCDExchange(MCD_EXCHANGE_ADDRESS).saiToDai(daiAmount);

        _paybackDebt(manager, _cdpId, daiAmount);

        //TODO: ratio check

        SaverLogger(LOGGER_ADDRESS).LogRepay(_cdpId, msg.sender, _collateralAmount, daiAmount);
    }

    function boost(uint _cdpId, address _collateralJoin, uint _daiAmount) public {
        //TODO: check slippage

        ManagerInterface manager = ManagerInterface(MANAGER_ADDRESS);

        _drawDai(manager, _cdpId, _daiAmount);

        address collateralAddr = address(GemJoinLike(_collateralJoin).gem());

        // TODO: remove only used for testing
        MCDExchange(MCD_EXCHANGE_ADDRESS).daiToSai(_daiAmount);

        //TODO: remove only used for testing
        ERC20(DAI_ADDRESS).transfer(MCD_EXCHANGE_ADDRESS, ERC20(DAI_ADDRESS).balanceOf(address(this)));

        ERC20(SAI_ADDRESS).approve(OASIS_TRADE, _daiAmount);
        //TODO: change to DAI address
        uint collateralAmount = OasisTrade(OASIS_TRADE).swap(SAI_ADDRESS, collateralAddr, _daiAmount);

        _addCollateral(manager, _cdpId, _collateralJoin, collateralAmount);

        //TODO: ratio check

        SaverLogger(LOGGER_ADDRESS).LogBoost(_cdpId, msg.sender, _daiAmount, collateralAmount);
    }


    function _drawDai(ManagerInterface _manager, uint _cdpId, uint _daiAmount) public {
        bytes32 ilk = _manager.ilks(_cdpId);

        // Update stability fee
        JugInterface(JUG_ADDRESS).drip(ilk);

        // TODO: check if _daiAmount > maxAmount

        _manager.frob(_cdpId, int(0), int(_daiAmount)); // draws Dai (TODO: dai amount helper function)
        _manager.move(_cdpId, address(this), _toRad(_daiAmount)); // moves Dai from Vat to Proxy

        if (VatInterface(VAT_ADDRESS).can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            VatInterface(VAT_ADDRESS).hope(DAI_JOIN_ADDRESS);
        }

        DaiJoinInterface(DAI_JOIN_ADDRESS).exit(address(this), _daiAmount);
    }

    function _addCollateral(ManagerInterface _manager, uint _cdpId, address _collateralJoin, uint _collateralAmount) public {
        int convertAmount = toInt(convertTo18(_collateralJoin, _collateralAmount));

        if (_collateralJoin == ETH_JOIN_ADDRESS) {
            GemJoinLike(_collateralJoin).gem().deposit.value(_collateralAmount)();
            convertAmount = toInt(_collateralAmount);
        }

        GemJoinLike(_collateralJoin).gem().approve(address(_collateralJoin), _collateralAmount);
        GemJoinLike(_collateralJoin).join(address(this), _collateralAmount);

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

    function _drawCollateral(ManagerInterface _manager, uint _cdpId, address _collateralJoin, uint _collateralAmount) public {
        //TODO: if _collateralAmount

        _manager.frob(
            _cdpId,
            address(this),
            -toInt(_collateralAmount),
            0
        );

        GemJoinLike(_collateralJoin).exit(address(this), _collateralAmount);

        if (_collateralJoin == ETH_JOIN_ADDRESS) {
            GemJoinLike(_collateralJoin).gem().withdraw(_collateralAmount);
            msg.sender.transfer(_collateralAmount);
        }
    }

    function _paybackDebt(ManagerInterface _manager, uint _cdpId, uint _daiAmount) public {
        address urn = _manager.urns(_cdpId);
        bytes32 ilk = _manager.ilks(_cdpId);

        DaiJoinLike(DAI_JOIN_ADDRESS).dai().approve(DAI_JOIN_ADDRESS, _daiAmount);

        DaiJoinLike(DAI_JOIN_ADDRESS).join(urn, _daiAmount);

        _manager.frob(_cdpId, 0, _getWipeDart(address(_manager.vat()), urn, ilk));
    }

    function getRatio() public returns (uint) {

    }

}
