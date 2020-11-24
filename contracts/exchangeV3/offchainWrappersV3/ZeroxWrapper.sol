pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/SafeERC20.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../DFSExchangeHelper.sol";
import "../../interfaces/OffchainWrapperInterface.sol";

contract ZeroxWrapper is OffchainWrapperInterface, DFSExchangeHelper, AdminAuth, DSMath {
    using SafeERC20 for ERC20;

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _type Action type (buy or sell)
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) override public payable returns (bool success, uint256) {
        // check that contract have enough balance for exchange and protocol fee
        require(getBalance(_exData.srcAddr) >= _exData.srcAmount);
        require(getBalance(KYBER_ETH_ADDRESS) >= _exData.offchainData.protocolFee);
        // src address can't be ETH addr, we are always dealing with WETH
        require(_exData.srcAddr != KYBER_ETH_ADDRESS);

        ERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, _exData.srcAmount);
        
        // write in the exact amount we are buing
        /// @dev for sells 0x uses max approve in v1
        /// @dev for buys we are still using v0 orders
        if (_type == ActionType.BUY) {
             writeUint256(_exData.offchainData.callData, 36, wdiv(_exData.destAmount, _exData.offchainData.price));
        }

        uint256 tokensBefore = getBalance(_exData.destAddr);
        (success, ) = _exData.offchainData.exchangeAddr.call{value: _exData.offchainData.protocolFee}(_exData.offchainData.callData);
        uint256 tokensSwaped = 0;

        if (success) {
            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(_exData.destAddr) - tokensBefore;
        }

        // returns all funds from src addr, dest addr and eth funds (protocol fee leftovers)
        sendLeftover(_exData.srcAddr, _exData.destAddr, msg.sender);

        return (success, tokensSwaped);
    }
}