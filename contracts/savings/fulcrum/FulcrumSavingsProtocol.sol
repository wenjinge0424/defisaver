pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/ITokenInterface.sol";
import "../../constants/ConstantAddresses.sol";
import "../../DS/DSAuth.sol";

contract FulcrumSavingsProtocol is ProtocolInterface, ConstantAddresses, DSAuth {

    address public savingsProxy;

    function addSavingsProxy(address _savingsProxy) public auth {
        savingsProxy = _savingsProxy;
    }

    function deposit(address _user, uint _amount) public {
        require(msg.sender == _user);

        // get dai from user
        require(ERC20(MAKER_DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        // approve dai to Fulcrum
        ERC20(MAKER_DAI_ADDRESS).approve(IDAI_ADDRESS, uint(-1));

        // mint iDai
        ITokenInterface(IDAI_ADDRESS).mint(_user, _amount);
    }

    function withdraw(address _user, uint _amount) public {
        require(msg.sender == _user);

        // transfer all users tokens to our contract
        require(ERC20(IDAI_ADDRESS).transferFrom(_user, address(this), ITokenInterface(IDAI_ADDRESS).balanceOf(_user)));

        // approve iDai to that contract
        ERC20(IDAI_ADDRESS).approve(IDAI_ADDRESS, uint(-1));

        // get dai from iDai contract
        ITokenInterface(IDAI_ADDRESS).burn(_user, _amount);

        // return all remaining tokens back to user
        require(ERC20(IDAI_ADDRESS).transfer(_user, ITokenInterface(IDAI_ADDRESS).balanceOf(address(this))));
    }
}
