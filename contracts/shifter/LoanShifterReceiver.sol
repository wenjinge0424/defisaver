pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./LoanShifterTaker.sol";
import "../auth/AdminAuth.sol";
import "../utils/FlashLoanReceiverBase.sol";
import "../interfaces/DSProxyInterface.sol";
import "../interfaces/ERC20.sol";
import "../exchange/SaverExchangeCore.sol";


contract LoanShifterReceiver is SaverExchangeCore, FlashLoanReceiverBase, AdminAuth {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    LoanShifterTaker loanShifterTaker = LoanShifterTaker(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    struct ParamData {
        bytes proxyData1;
        bytes proxyData2;
        address proxy;
        address debtAddr;
        uint8 protocol1;
        uint8 protocol2;
    }

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {
        // Format the call data for DSProxy
        (ParamData memory paramData, ExchangeData memory exchangeData)
                                 = packFunctionCall(_amount, _params);

        address protocolAddr1 = loanShifterTaker.getProtocolAddr(LoanShifterTaker.Protocols(paramData.protocol1));
        require(protocolAddr1 != address(0), "Protocol1 addr not found");

        address protocolAddr2 = loanShifterTaker.getProtocolAddr(LoanShifterTaker.Protocols(paramData.protocol2));
        require(protocolAddr2 != address(0), "Protocol2 addr not found");

        // Send Flash loan amount to DSProxy
        sendLoanToProxy(payable(paramData.proxy), _reserve, _amount);

        // Execute the Close operation
        DSProxyInterface(paramData.proxy).execute(protocolAddr1, paramData.proxyData1);

        if (paramData.protocol1 != paramData.protocol2) {
            if (paramData.debtAddr == exchangeData.srcAddr) {
                _buy(exchangeData);
            } else {
                _sell(exchangeData);
            }
        }

        // Execute the Open operation
        DSProxyInterface(paramData.proxy).execute(protocolAddr2, paramData.proxyData2);

        // Repay FL
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function packFunctionCall(uint _amount, bytes memory _params)
        internal pure returns (ParamData memory paramData, ExchangeData memory exchangeData) {

        (
            uint[8] memory numData, // collAmount, debtAmount, id1, id2, srcAmount, destAmount, minPrice, price0x
            address[6] memory addrData, // addrLoan1, addrLoan2, debtAddr, srcAddr, destAddr, exchangeAddr
            uint8[3] memory enumData, // fromProtocol, toProtocol, exchangeType
            bytes memory callData,
            address proxy
        )
        = abi.decode(_params, (uint256[8],address[6],uint8[3],bytes,address));

        bytes memory proxyData1;
        bytes memory proxyData2;

        if (enumData[0] == uint8(LoanShifterTaker.Protocols.MCD)) {
            proxyData1 = abi.encodeWithSignature(
            "close(uint256,address,uint256,uint256)",
                                numData[2], addrData[0], _amount, numData[0]);

            proxyData2 = abi.encodeWithSignature(
            "open(uint256,address,uint256,uint256)",
                                numData[3], addrData[1], _amount, numData[1]);
        } else if(enumData[0] == uint8(LoanShifterTaker.Protocols.COMPOUND)) {
            proxyData1 = abi.encodeWithSignature(
            "close(address,address,uint256,uint256)",
                                addrData[0], addrData[2], numData[0], numData[1]);

            // TODO: check this?
            address debtAddr2 = addrData[4] == addrData[2] ? addrData[2] : addrData[4];

            proxyData2 = abi.encodeWithSignature(
            "open(address,address,uint256,uint256)",
                                addrData[1], debtAddr2, numData[0], numData[1]);
        }


        paramData = ParamData({
            proxyData1: proxyData1,
            proxyData2: proxyData2,
            debtAddr: addrData[2],
            proxy: proxy,
            protocol1: enumData[0],
            protocol2: enumData[1]
        });

        exchangeData = SaverExchangeCore.ExchangeData({
            srcAddr: addrData[3],
            destAddr: addrData[4],
            srcAmount: numData[4],
            destAmount: numData[5],
            minPrice: numData[6],
            exchangeType: ExchangeType(enumData[2]),
            exchangeAddr: addrData[5],
            callData: callData,
            price0x: numData[7]
        });

    }

    function sendLoanToProxy(address payable _proxy, address _reserve, uint _amount) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).transfer(_proxy, _amount);
        }

        _proxy.transfer(address(this).balance);
    }

    function setLoanShiftTaker(address _loanShiftTaker) onlyOwner public {
        loanShifterTaker = LoanShifterTaker(_loanShiftTaker);
    }

    receive() external override(FlashLoanReceiverBase, SaverExchangeCore) payable {}
}
