pragma solidity ^0.5.0;

import "../../flashloan/aave/FlashLoanReceiverBase.sol";
import "../../interfaces/DSProxyInterface.sol";

contract CompoundSaverFlashLoan is FlashLoanReceiverBase {
    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address payable public constant COMPOUND_SAVER_FLASH_PROXY = 0x86E132932566fb7030eeF19B997C8797De13CFBD;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
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
            uint[5] memory data, // amount, minPrice, exchangeType, gasCost, 0xPrice
            address[3] memory addrData, // cCollAddress, cBorrowAddress, exchangeAddress
            bytes memory callData,
            bool isRepay,
            address payable proxyAddr
        )
        = abi.decode(_params, (uint256[5],address[3],bytes,bool,address));

        bytes memory proxyData;

        if (isRepay) {
            proxyData = abi.encodeWithSignature("flashRepay(uint256[5],address[3],bytes)", data, addrData, callData);
        } else {
            proxyData = abi.encodeWithSignature("flashBoost(uint256[5],address[3],bytes)", data, addrData, callData);
        }

        DSProxyInterface(proxyAddr).execute(COMPOUND_SAVER_FLASH_PROXY, proxyData);

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function() external payable {}

}
