pragma solidity ^0.5.0;

import "../../mcd/maker/Join.sol";
import "../../DS/DSMath.sol";

contract VatLike {
    function can(address, address) public view returns (uint);
    function ilks(bytes32) public view returns (uint, uint, uint, uint, uint);
    function dai(address) public view returns (uint);
    function urns(bytes32, address) public view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) public;
    function hope(address) public;
    function move(address, address, uint) public;
}

contract PotLike {
    function chi() public view returns (uint);
    function pie(address) public view returns (uint);
    function drip() public;
    function join(uint) public;
    function exit(uint) public;
}

contract GemLike {
    function approve(address, uint) public;
    function transfer(address, uint) public;
    function transferFrom(address, address, uint) public;
    function deposit() public payable;
    function withdraw(uint) public;
}

contract DaiJoinLike {
    function vat() public returns (VatLike);
    function dai() public returns (GemLike);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract DSRProtocol is DSMath {

    // Kovan not sure what are mainnet addrs
    address public constant DAI_JOIN_ADDRESS = 0x61Af28390D0B3E806bBaF09104317cb5d26E215D;
    address public constant POT_ADDRESS = 0x24e89801DAD4603a3E2280eE30FB77f183Cb9eD9;

    function dsrDeposit(uint _amount) internal {
        VatLike vat = DaiJoinLike(DAI_JOIN_ADDRESS).vat();

        PotLike(POT_ADDRESS).drip();

        daiJoin_join(DAI_JOIN_ADDRESS, address(this), _amount);

        if (vat.can(address(this), address(POT_ADDRESS)) == 0) {
            vat.hope(POT_ADDRESS);
        }

        PotLike(POT_ADDRESS).join(mul(_amount, RAY) / PotLike(POT_ADDRESS).chi());
    }

    function dsrWithdraw(uint _amount) internal {
        VatLike vat = DaiJoinLike(DAI_JOIN_ADDRESS).vat();

        PotLike(POT_ADDRESS).drip();

        uint pie = mul(_amount, RAY) / PotLike(POT_ADDRESS).chi();

        PotLike(POT_ADDRESS).exit(pie);

        uint bal = DaiJoinLike(DAI_JOIN_ADDRESS).vat().dai(address(this));

        if (vat.can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            vat.hope(DAI_JOIN_ADDRESS);
        }

        DaiJoinLike(DAI_JOIN_ADDRESS).exit(
            msg.sender,
            bal >= mul(_amount, RAY) ? _amount : bal / RAY
        );
    }


    function daiJoin_join(address apt, address urn, uint wad) internal {
        DaiJoinLike(apt).dai().transferFrom(msg.sender, address(this), wad);

        DaiJoinLike(apt).dai().approve(apt, wad);

        DaiJoinLike(apt).join(urn, wad);
    }
}
