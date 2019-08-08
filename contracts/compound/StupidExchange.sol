pragma solidity ^0.5.0;

import "../interfaces/ERC20.sol";
import "../ConstantAddresses.sol";

/// @title Used only on kovan as a helper because different Dai tokens are used in Maker | Compound
contract StupidExchange is ConstantAddresses {

    function getMakerDaiToken(uint _amount) public {
        ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, _amount);
    }

    function getCompoundDaiToken(uint _amount) public {
        ERC20(COMPOUND_DAI_ADDRESS).transfer(msg.sender, _amount);
    }
}
