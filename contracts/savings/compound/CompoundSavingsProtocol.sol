pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../compound/Exponential.sol";
import "../../compound/StupidExchange.sol";
import "../../interfaces/ERC20.sol";
import "../../constants/ConstantAddresses.sol";
import "../../DS/DSAuth.sol";


contract CompoundSavingsProtocol is ProtocolInterface, Exponential, ConstantAddresses, DSAuth {

    CTokenInterface public cDaiContract;
    address public savingsProxy;

    constructor() public {
        cDaiContract = CTokenInterface(CDAI_ADDRESS);
    }

    function addSavingsProxy(address _savingsProxy) public auth {

        savingsProxy = _savingsProxy;
    }

    function deposit(address _user, uint _amount) public {
        require(msg.sender == savingsProxy);
        // get dai from user
        require(ERC20(MAKER_DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        // // REMOVE: USED ONLY ON KOVAN TO HANDLE DAI DIFFERENT TOKENS
        // StupidExchange(STUPID_EXCHANGE).getCompoundDaiToken(_amount);
        // // approve dai to compound
        // ERC20(COMPOUND_DAI_ADDRESS).approve(CDAI_ADDRESS, uint(-1));

        // mainnet only
        ERC20(MAKER_DAI_ADDRESS).approve(CDAI_ADDRESS, uint(-1));

        // mint cDai
        require(cDaiContract.mint(_amount) == 0, "Failed Mint");
        // balance should be equal to cDai minted
        uint cDaiMinted = cDaiContract.balanceOf(address(this));
        // return cDai to user
        ERC20(CDAI_ADDRESS).transfer(_user, cDaiMinted);
    }

    function withdraw(address _user, uint _amount) public {
        require(msg.sender == savingsProxy);
        // transfer all users balance to this contract
        require(ERC20(CDAI_ADDRESS).transferFrom(_user, address(this), ERC20(CDAI_ADDRESS).balanceOf(_user)));
        // approve cDai to compound contract
        ERC20(CDAI_ADDRESS).approve(address(cDaiContract), uint(-1));
        // get dai from cDai contract
        require(cDaiContract.redeemUnderlying(_amount) == 0, "Reedem Failed");

        // REMOVE: USED ONLY ON KOVAN TO HANDLE DAI DIFFERENT TOKENS
        // StupidExchange(STUPID_EXCHANGE).getMakerDaiToken(_amount);

        // return to user balance we didn't spend
        uint cDaiBalance = ERC20(CDAI_ADDRESS).balanceOf(address(this));
        if (cDaiBalance > 0) {
            ERC20(CDAI_ADDRESS).transfer(_user, cDaiBalance);
        }
        // return dai we have to user
        ERC20(MAKER_DAI_ADDRESS).transfer(_user, _amount);
    }
}
