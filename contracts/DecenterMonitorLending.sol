pragma solidity ^0.5.0;

import "./interfaces/CTokenInterface.sol";
import "./compound/StupidExchange.sol";
import "./constants/ConstantAddresses.sol";

contract DecenterMonitorLending is ConstantAddresses {

    //Kovan
    CTokenInterface public cDai = CTokenInterface(CDAI_ADDRESS);
    ERC20 public dai = ERC20(COMPOUND_DAI_ADDRESS);

    address owner;
    address monitor;

    constructor(address _owner, address _monitor) public {
        owner = _owner;
        monitor = _monitor;

        dai.approve(address(cDai), uint(-1));
        cDai.approve(address(cDai), uint(-1));
    }

    function borrow(uint _daiAmount, address _to) public {
        require(msg.sender == monitor, "Only our monitor contract can borrow");

        require(cDai.redeemUnderlying(_daiAmount) == 0, "Get Dai from our cDai");

        dai.transfer(_to, _daiAmount);
    }

    function deposit(uint _daiAmount) public {
        require(msg.sender == monitor || msg.sender == owner);

        dai.transferFrom(msg.sender, address(this), _daiAmount);

        require(cDai.mint(_daiAmount) == 0, "Get cDai from our Dai");
    }

    function withdraw(uint _cDaiAmount) public {
        require(msg.sender == owner, "Only owner can withdraw");

        cDai.transfer(owner, _cDaiAmount);
    }
}
