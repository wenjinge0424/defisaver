pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/SafeERC20.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../DFSExchangeHelper.sol";
import "../../interfaces/OffchainWrapperInterface.sol";
import "../../interfaces/TokenInterface.sol";

contract ScpWrapper is OffchainWrapperInterface, DFSExchangeHelper, AdminAuth, DSMath {

    string public constant ERR_SRC_AMOUNT = "Not enough funds";
    string public constant ERR_PROTOCOL_FEE = "Not enough eth for protcol fee";
    string public constant ERR_TOKENS_SWAPED_ZERO = "Order success but amount 0";

    using SafeERC20 for ERC20;

    /// @notice Takes order from Scp and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _type Action type (buy or sell)
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) override public payable returns (bool success, uint256) {
        // check that contract have enough balance for exchange and protocol fee
        require(getBalance(_exData.srcAddr) >= _exData.srcAmount, ERR_SRC_AMOUNT);
        require(getBalance(KYBER_ETH_ADDRESS) >= _exData.offchainData.protocolFee, ERR_PROTOCOL_FEE);

        ERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, _exData.srcAmount);

        // write in the exact amount we are selling/buing in an order
        if (_type == ActionType.SELL) {
            writeUint256(_exData.offchainData.callData, 36, _exData.srcAmount);
        } else {
            writeUint256(_exData.offchainData.callData, 36, wdiv(_exData.destAmount, _exData.offchainData.price));
        }

        // we know that it will be eth if dest addr is either weth or eth
        address destAddr = _exData.destAddr == KYBER_ETH_ADDRESS ? EXCHANGE_WETH_ADDRESS : _exData.destAddr;

        uint256 tokensBefore = getBalance(destAddr);
        (success, ) = _exData.offchainData.exchangeAddr.call{value: _exData.offchainData.protocolFee}(_exData.offchainData.callData);
        uint256 tokensSwaped = 0;


        if (success) {
            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(destAddr) - tokensBefore;
            require(tokensSwaped > 0, ERR_TOKENS_SWAPED_ZERO);
        }

        // returns all funds from src addr, dest addr and eth funds (protocol fee leftovers)
        sendLeftover(_exData.srcAddr, _exData.destAddr, msg.sender);

        return (success, tokensSwaped);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}
