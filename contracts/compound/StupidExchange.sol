pragma solidity ^0.5.0;

import "../interfaces/ERC20.sol";

/// @title Used only on kovan as a helper because different Dai tokens are used in Maker | Compound
contract StupidExchange {
    address public constant MAKER_DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public constant COMPOUND_DAI_ADDRESS = 0x25a01a05C188DaCBCf1D61Af55D4a5B4021F7eeD;

    function getMakerDaiToken(uint _amount) public {
        ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, _amount);
    }

    function getCompoundDaiToken(uint _amount) public {
        ERC20(COMPOUND_DAI_ADDRESS).transfer(msg.sender, _amount);
    }
}
