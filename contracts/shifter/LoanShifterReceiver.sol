pragma solidity ^0.6.0;

import "./LoanShifterTaker.sol";
import "../utils/FlashLoanReceiverBase.sol";
import "../interfaces/DSProxyInterface.sol";
import "../interfaces/ERC20.sol";

contract LoanShifterReceiver is FlashLoanReceiverBase {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address payable public owner;

    LoanShifterTaker loanShifterTaker = LoanShifterTaker(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

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
        (bytes memory proxyData, address payable proxyAddr, uint8 protocol)
                                 = packFunctionCall(_amount, _fee, _params);

        address protocolAddr = loanShifterTaker.getProtocolAddr(LoanShifterTaker.Protocols(protocol));
        require(protocolAddr != address(0), "Protocol addr not found");

        // Send Flash loan amount to DSProxy
        sendLoanToProxy(proxyAddr, _reserve, _amount);

        // Execute the DSProxy call
        DSProxyInterface(proxyAddr).execute(protocolAddr, proxyData);

        // Repay FL
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function packFunctionCall(uint _amount, uint _fee, bytes memory _params)
        internal view returns (bytes memory proxyData, address payable, uint8) {

        (
            uint8 protocol,
            uint id1,
            address addrLoan1,
            uint collAmount,
            uint debtAmount,
            address payable proxyAddr
        )
        = abi.decode(_params, (uint8,uint256,address,uint256,uint256,address));

        if (protocol == uint8(LoanShifterTaker.Protocols.MCD)) {
            proxyData = abi.encodeWithSignature(
                "close(uint256,address,uint256,uint256,address)",
                                    id1, addrLoan1, _amount, collAmount, address(loanShifterTaker));
        }

        return (proxyData, proxyAddr, protocol);
    }

    function sendLoanToProxy(address payable _proxy, address _reserve, uint _amount) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).transfer(_proxy, _amount);
        }

        _proxy.transfer(address(this).balance);
    }

}
