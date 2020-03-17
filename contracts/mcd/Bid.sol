pragma solidity ^0.5.0;

import "./maker/Join.sol";
import "../interfaces/ERC20.sol";
import "./maker/Vat.sol";
import "./maker/Flipper.sol";
import "./maker/Gem.sol";

contract Bid {

    address public constant ETH_FLIPPER = 0xd8a04F5412223F513DC55F839574430f5EC15531;
    address public constant BAT_FLIPPER = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant DAI_JOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant ETH_JOIN = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address public constant BAT_JOIN = 0x3D0B1912B66114d4096F48A8CEe3A56C231772cA;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    bytes32 public constant BAT_ILK = 0x4241542d41000000000000000000000000000000000000000000000000000000;
    bytes32 public constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    function bid(uint _bidId, bool _isEth, uint _amount) public {
        uint tendAmount = _amount * (10 ** 27);

        uint lot;
        if (_isEth) {
            (, lot, , , , , , ) = Flipper(ETH_FLIPPER).bids(_bidId);
        } else {
            (, lot, , , , , , ) = Flipper(BAT_FLIPPER).bids(_bidId);
        }

        ERC20(DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount);
        ERC20(DAI_ADDRESS).approve(DAI_JOIN, _amount);
        Join(DAI_JOIN).join(address(this), _amount);

        Vat(VAT_ADDRESS).hope(ETH_FLIPPER);
        Vat(VAT_ADDRESS).hope(BAT_FLIPPER);

        if (_isEth) {
            Flipper(ETH_FLIPPER).tend(_bidId, lot, tendAmount);
        } else {
            Flipper(BAT_FLIPPER).tend(_bidId, lot, tendAmount);
        }
    }

    function phase2(uint _bidId, bool _isEth, uint _amount) public {
        address flipper = _isEth ? ETH_FLIPPER : BAT_FLIPPER;

        uint bid;
        (bid, , , , , , , ) = Flipper(flipper).bids(_bidId);

        Flipper(flipper).dent(_bidId, _amount, bid);
    }

    function close(uint _bidId, bool _isEth) public {
        if (_isEth) {
            Flipper(ETH_FLIPPER).deal(_bidId);
            uint amount = Vat(VAT_ADDRESS).gem(ETH_ILK, address(this)) / (10**27);

            Vat(VAT_ADDRESS).hope(ETH_JOIN);
            Gem(ETH_JOIN).exit(msg.sender, amount);
        } else {
            Flipper(BAT_FLIPPER).deal(_bidId);
            uint amount = Vat(VAT_ADDRESS).gem(BAT_ILK, address(this)) / (10**27);

            Vat(VAT_ADDRESS).hope(BAT_JOIN);
            Gem(BAT_JOIN).exit(msg.sender, amount);
        }
    }

    function exitDai() public {
        uint amount = Vat(VAT_ADDRESS).dai(address(this)) / (10**27);

        Vat(VAT_ADDRESS).hope(DAI_JOIN);
        Gem(DAI_JOIN).exit(msg.sender, amount);
    }

    function withdrawDai() public {
        uint balance = ERC20(DAI_ADDRESS).balanceOf(address(this));
        ERC20(DAI_ADDRESS).transfer(msg.sender, balance);
    }

    function withdrawToken(address _token) public {
        uint balance = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(msg.sender, balance);
    }

    function withdrawEth() public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}
