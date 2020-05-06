pragma solidity ^0.6.0;

import "../aave/FlashLoanReceiverBase.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../../interfaces/ERC20.sol";

contract LoanMover is FlashLoanReceiverBase {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant cDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    address public constant LOAN_MOVER_PROXY = 0x2e28E2673777d9B35424A9a4f88502b5A1538D9E;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

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
    external override {
        // Format the call data for DSProxy
        (bytes memory proxyData, address payable proxyAddr) = packFunctionCall(_amount, _fee, _params);

        // Send Flash loan amount to DSProxy
        sendLoanToProxy(proxyAddr, _reserve, _amount);

        // Execute the DSProxy call
        DSProxyInterface(proxyAddr).execute(LOAN_MOVER_PROXY, proxyData);

        // Repay FL
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function packFunctionCall(uint _amount, uint _fee, bytes memory _params) internal pure returns (bytes memory proxyData, address payable) {
        (
            uint cdpId,
            address joinAddr,
            address cCollateralAddr,
            bytes32 ilk,
            uint8 functionType,
            address payable proxyAddr
        )
        = abi.decode(_params, (uint256,address,address,bytes32,uint8,address));

        if (functionType == 1) {
            proxyData = abi.encodeWithSignature(
                "flashCompound2Maker(uint256,address,address,bytes32,uint256,uint256)",
                                    cdpId, joinAddr, cCollateralAddr, ilk, _amount, _fee);
        } else if(functionType == 2) {
            proxyData = abi.encodeWithSignature(
                "flashMaker2Compound(uint256,address,address,bytes32,uint256,uint256)",
                                    cdpId, joinAddr, cCollateralAddr, ilk, _amount, _fee);
        }

        return (proxyData, proxyAddr);
    }

    function sendLoanToProxy(address payable _proxy, address _reserve, uint _amount) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).transfer(_proxy, _amount);
        }

        _proxy.transfer(address(this).balance);
    }

}
