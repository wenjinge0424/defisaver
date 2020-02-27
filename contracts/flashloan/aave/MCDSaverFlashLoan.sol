pragma solidity ^0.5.0;

import "../../mcd/saver_proxy/MCDSaverProxy.sol";
import "./FlashLoanReceiverBase.sol";

contract MCDSaverFlashLoan is MCDSaverProxy, FlashLoanReceiverBase {
    Manager public constant MANAGER = Manager(MANAGER_ADDRESS);

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5);

    address payable public owner;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
            owner = msg.sender;
        }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params) 
    external {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve), 
            "Invalid balance for the contract");

        (
            uint[6] memory data,
            uint loanAmount,
            address joinAddr,
            address exchangeAddress,
            bytes memory callData,
            bool isRepay
        ) 
         = abi.decode(_params, (uint256[6],uint256,address,address,bytes,bool));

        actionWithLoan(data, loanAmount, joinAddr, exchangeAddress, callData, isRepay, _fee);

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    function actionWithLoan(
        uint256[6] memory _data,
        uint256 _loanAmount,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData,
        bool _isRepay,
        uint _fee
    ) internal {
        // payback the CDP debt with loan amount
        address owner = getOwner(MANAGER, _data[0]);
        paybackDebt(_data[0], MANAGER.ilks(_data[0]), _loanAmount, owner);

        if (_isRepay) {
            repay(_data, _joinAddr, _exchangeAddress, _callData);
        } else {
            boost(_data, _joinAddr, _exchangeAddress, _callData);
        }

        // Draw loanedAmount + fee
        uint256 daiDrawn = drawDai(_data[0], MANAGER.ilks(_data[0]), _loanAmount + _fee);
    }

    function() external payable {}

    // ADMIN ONLY FAIL SAFE FUNCTION IF FUNDS GET STUCK
    function withdrawStuckFunds(address _tokenAddr, uint _amount) public {
        require(msg.sender == owner, "Only owner");

        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            owner.transfer(_amount);
        } else {
            ERC20(_tokenAddr).transfer(owner, _amount);
        }
    }
}
