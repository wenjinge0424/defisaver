pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "../../interfaces/ERC20.sol";

contract ITokenInterface {
    function mint(address receiver, uint256 depositAmount) external returns(uint256 mintAmount);
    function burn(address receiver, uint256 burnAmount) external returns(uint256 loanAmountPaid);
    function balanceOf(address _owner) external view returns (uint balance);
}

contract FulcrumSavingsProtocol is ProtocolInterface {

    // kovan
    address public constant MAKER_DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public constant IDAI_ADDRESS = 0xb6b09fBffBa6A5C4631e5F7B2e3Ee183aC259c0d;

    function deposit(address _user, uint _amount) public {
        // get dai from user
        require(ERC20(MAKER_DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        // approve dai to Fulcrum
        ERC20(MAKER_DAI_ADDRESS).approve(IDAI_ADDRESS, uint(-1));

        // mint iDai
        ITokenInterface(IDAI_ADDRESS).mint(msg.sender, _amount);
    }

    function withdraw(address _user, uint _amount) public {
        // transfer all users tokens to our contract
        require(ERC20(IDAI_ADDRESS).transferFrom(_user, address(this), ITokenInterface(IDAI_ADDRESS).balanceOf(msg.sender)));

        // approve iDai to that contract
        ERC20(IDAI_ADDRESS).approve(IDAI_ADDRESS, uint(-1));

        // get dai from iDai contract
        ITokenInterface(IDAI_ADDRESS).burn(msg.sender, _amount);

        // return all remaining tokens back to user
        require(ERC20(IDAI_ADDRESS).transfer(_user, ITokenInterface(IDAI_ADDRESS).balanceOf(address(this))));
    }
}
