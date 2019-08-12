pragma solidity ^0.5.0;

import "./interfaces/ERC20.sol";
import "./ReentrancyGuard.sol";
import "./DS/DSMath.sol";
import "./constants/ConstantAddresses.sol";

contract CTokenInterface is ERC20 {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);
}

contract SaverProxy {
    function repay(bytes32 _cup, uint _amount, uint _minAmount) public;
    function boost(bytes32 _cup, uint _amount, uint _minAmount) public;
}

/// @title Contract will hold cDai and use it for users to borrow and return in the sam tx
contract DecenterLending is ReentrancyGuard, DSMath, ConstantAddresses {

    //Kovan
    CTokenInterface public cDai = CTokenInterface(CTOKEN_INTERFACE);
    ERC20 public Dai = ERC20(COMPOUND_DAI_ADDRESS);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;
    address public feeAddress;
    uint public feeAmount;
    uint public sanityBalance;
    address public sanityContractAddress;

    constructor(address _owner, uint _feeAmount, address _feeAddress) public {
        owner = _owner;
        feeAmount = _feeAmount;
        feeAddress = _feeAddress;
    }

    function borrow(uint _amountToBorrow, uint _type, bytes32 _cup, uint _amount, uint _minAmount) public nonReentrant {

        require(cDai.redeemUnderlying(_amountToBorrow) == 0, "Reedem failed");

        uint prevDaiBalance = Dai.balanceOf(address(this));

        //Send money
        Dai.transfer(msg.sender, _amountToBorrow);

        if (_type == 1) {
            SaverProxy(msg.sender).repay(_cup, _amount, _minAmount);
        } else {
            SaverProxy(msg.sender).boost(_cup, _amount, _minAmount);
        }


        uint currentDaiBalance = Dai.balanceOf(address(this));

        // if feeAmount is 0, feeEarned will be 0
        uint feeEarned = _amountToBorrow / feeAmount;

        //Where my money bitch
        require(currentDaiBalance >= add(prevDaiBalance, feeEarned));

        // Transfer the fee earned to the feeAddress
        Dai.transfer(feeAddress, feeEarned);

        require(Dai.balanceOf(sanityContractAddress) >= sanityBalance, "Sanity check against hackers");

        require(cDai.mint(_amountToBorrow) == 0, "Mint failed");
    }


    // ADMIN ONLY

    // Owner can get his money back
    function withdraw(uint _amount, address _tokenAddress) public onlyOwner {
        ERC20(_tokenAddress).transfer(owner, _amount);
    }

    function changeFee(uint _newFee) public onlyOwner {
        feeAmount = _newFee;
    }

    function setSanityAmount(uint _sanityAmount) public onlyOwner {
        sanityBalance = _sanityAmount;
    }

    function setSanityContractAddress(address _contractAddress) public onlyOwner {
        sanityContractAddress = _contractAddress;
    }
}
