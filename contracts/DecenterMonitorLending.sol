pragma solidity ^0.5.0;

import "./interfaces/CTokenInterface.sol";
import "./compound/StupidExchange.sol";

contract DecenterMonitorLending {

    //Kovan
    CTokenInterface public cDai = CTokenInterface(0xb6b09fBffBa6A5C4631e5F7B2e3Ee183aC259c0d);
    ERC20 public dai = ERC20(0x25a01a05C188DaCBCf1D61Af55D4a5B4021F7eeD);

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