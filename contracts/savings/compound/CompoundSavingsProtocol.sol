pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../compound/Exponential.sol";
import "../../compound/StupidExchange.sol";
import "../../interfaces/ERC20.sol";

contract CompoundSavingsProtocol is ProtocolInterface, Exponential {

    // kovan
    // address public constant MAKER_DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    // address public constant CDAI_ADDRESS = 0xb6b09fBffBa6A5C4631e5F7B2e3Ee183aC259c0d;
    // address public constant COMPOUND_DAI_ADDRESS = 0x25a01a05C188DaCBCf1D61Af55D4a5B4021F7eeD;
    // address public constant STUPID_EXCHANGE = 0x863E41FE88288ebf3fcd91d8Dbb679fb83fdfE17;

    // mainnet
    address public constant MAKER_DAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public constant CDAI_ADDRESS = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;


    CTokenInterface public cDaiContract;

    constructor() public {
        cDaiContract = CTokenInterface(CDAI_ADDRESS);
    }

    function deposit(address _user, uint _amount) public {
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
