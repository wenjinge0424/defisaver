pragma solidity ^0.5.0;

import "../../mcd/saver_proxy/MCDSaverProxy.sol";
import "./FlashLoanReceiverBase.sol";

contract ManagerLike {
    function ilks(uint256) public view returns (bytes32);
}

contract MCDSaverFlashProxy is MCDSaverProxy, FlashLoanReceiverBase {
    Manager public constant MANAGER = Manager(MANAGER_ADDRESS);

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
}
