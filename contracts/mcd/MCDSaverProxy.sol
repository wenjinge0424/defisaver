pragma solidity ^0.5.0;

import "../DS/DSMath.sol";

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

contract MCDSaverProxy is DSMath {

    // KOVAN
    address public constant VAT_ADDRESS = 0x6e6073260e1a77dFaf57D0B92c44265122Da8028;
    address public constant MANAGER_ADDRESS = 0x1Cb0d969643aF4E929b3FafA5BA82950e31316b8;
    address public constant JUG_ADDRESS = 0x3793181eBbc1a72cc08ba90087D21c7862783FA5;
    address public constant DAI_JOIN_ADDRESS = 0x61Af28390D0B3E806bBaF09104317cb5d26E215D;

    // function repay(uint _cdpId) public {

    // }

    function boost(uint _cdpId, uint _daiAmount, uint _slippageLimit, uint _exchangeType) public {
        // check slippage

        _drawDai(_cdpId, _daiAmount);

        // convert on exchange to collateral

        _addCollateral(_cdpId, _daiAmount);

        // ratio check

        // logs

    }


    function _drawDai(uint _cdpId, uint _daiAmount) public {
        ManagerInterface manager = ManagerInterface(MANAGER_ADDRESS);
        bytes32 ilk = manager.ilks(_cdpId);

        // Update stability fee
        JugInterface(JUG_ADDRESS).drip(ilk);

        manager.frob(_cdpId, int(0), int(_daiAmount)); // draws Dai (TODO: dai amount helper function)
        manager.move(_cdpId, address(this), _toRad(_daiAmount)); // moves Dai from Vat to Proxy

        if (VatInterface(VAT_ADDRESS).can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            VatInterface(VAT_ADDRESS).hope(DAI_JOIN_ADDRESS);
        }

        DaiJoinInterface(DAI_JOIN_ADDRESS).exit(address(this), _daiAmount);
    }

    function _addCollateral(uint _cdpId, uint _daiAmount) public {

    }

    function _toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }

}
