pragma solidity ^0.5.0;

import "../../interfaces/OsmMom.sol";
import "../../interfaces/Osm.sol";
import "../../auth/AdminAuth.sol";
import "../maker/Manager.sol";

contract MCDPriceVerifier is AdminAuth {

    OsmMom public osmMom = OsmMom(0x76416A4d5190d071bfed309861527431304aA14f);
    Manager public manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    mapping(address => bool) public authorized;

    function verifyNextPriceWithCdpId(uint _nextPrice, uint _cdpId) public view returns(bool) {
        require(authorized[msg.sender]);

        bytes32 ilk = manager.ilks(_cdpId);

        return verifyNextPrice(_nextPrice, ilk);
    }

    function verifyNextPrice(uint _nextPrice, bytes32 _ilk) public view returns(bool) {
        require(authorized[msg.sender]);

        address osmAddress = osmMom.osms(_ilk);
        
        bytes32 price32;
        bool has;
        (price32, has) = Osm(osmAddress).peep();

        return has ? uint(price32) == _nextPrice : false;
    } 

    function setAuthorized(address _address, bool _allowed) public onlyOwner {
        authorized[_address] = _allowed;
    }
}
