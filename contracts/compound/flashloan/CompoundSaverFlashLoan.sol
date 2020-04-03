pragma solidity ^0.5.0;

import "../../flashloan/aave/FlashLoanReceiverBase.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../../interfaces/ERC20.sol";

contract CompoundSaverFlashLoan is FlashLoanReceiverBase {
    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address payable public constant COMPOUND_SAVER_FLASH_PROXY = 0x86E132932566fb7030eeF19B997C8797De13CFBD;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

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
        // Format the call data for DSProxy
        (bytes memory proxyData, address payable proxyAddr) = packFunctionCall(_amount, _fee, _params);

        // Send Flash loan amount to DSProxy
        sendLoanToProxy(proxyAddr, _reserve, _amount);

        // Execute the DSProxy call
        DSProxyInterface(proxyAddr).execute(COMPOUND_SAVER_FLASH_PROXY, proxyData);

        // Repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    function packFunctionCall(uint _amount, uint _fee, bytes memory _params) internal returns (bytes memory proxyData, address payable) {
        (
            uint[5] memory data, // amount, minPrice, exchangeType, gasCost, 0xPrice
            address[3] memory addrData, // cCollAddress, cBorrowAddress, exchangeAddress
            bytes memory callData,
            bool isRepay,
            address payable proxyAddr
        )
        = abi.decode(_params, (uint256[5],address[3],bytes,bool,address));

        uint[2] memory flashLoanData = [_amount, _fee];

        if (isRepay) {
            proxyData = abi.encodeWithSignature("flashRepay(uint256[5],address[3],bytes,uint256[2])", data, addrData, callData, flashLoanData);
        } else {
            proxyData = abi.encodeWithSignature("flashBoost(uint256[5],address[3],bytes,uint256[2])", data, addrData, callData, flashLoanData);
        }

        return (proxyData, proxyAddr);
    }

    function sendLoanToProxy(address payable _proxy, address _reserve, uint _amount) internal {
        if (_reserve == ETH_ADDRESS) {
            _proxy.transfer(_amount);
        } else {
            ERC20(_reserve).transfer(_proxy, _amount);
        }
    }

    function() external payable {}
}
