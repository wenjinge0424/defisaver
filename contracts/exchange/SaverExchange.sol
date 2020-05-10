pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SaverExchangeCore.sol";
import "../DS/DSMath.sol";
import "../loggers/ExchangeLogger.sol";

contract SaverExchange is SaverExchangeCore, DSMath {

    uint256 public constant SERVICE_FEE = 800; // 0.125% Fee

    // solhint-disable-next-line const-name-snakecase
    ExchangeLogger public constant logger = ExchangeLogger(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function sell(ExchangeData memory exData) public payable {
        // transfer tokens from the user
        pullTokens(exData.srcAddr, exData.srcAmount);

        // take fee
        uint dfsFee = takeFee(exData.srcAmount, exData.srcAddr);
        exData.srcAmount = sub(exData.srcAmount, dfsFee);

        // Perform the exchange
        (address wrapper, uint swapedTokens) = _sell(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr);

        // log the event
        logger.logSwap(exData.srcAddr, exData.destAddr, exData.srcAmount, swapedTokens, wrapper);
    }

    /// @dev srcAmount when using 0x should be bigger by fee amount
    function buy(ExchangeData memory exData) public payable {
        // transfer tokens from the user
        pullTokens(exData.srcAddr, exData.srcAmount);

        uint dfsFee = takeFee(exData.srcAmount, exData.srcAddr);
        exData.srcAmount = sub(exData.srcAmount, dfsFee);

        // Perform the exchange
        (address wrapper, uint swapedTokens) = _buy(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr);

        // log the event
        logger.logSwap(exData.srcAddr, exData.destAddr, exData.srcAmount, swapedTokens, wrapper);
    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @return feeAmount Amount in Dai owner earned on the fee
    function takeFee(uint256 _amount, address _token) internal returns (uint256 feeAmount) {
        uint256 fee = SERVICE_FEE;

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(msg.sender)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(msg.sender);
        }

        if (fee == 0) {
            feeAmount = 0;
        } else {
            feeAmount = _amount / SERVICE_FEE;
            if (_token == KYBER_ETH_ADDRESS || _token == WETH_ADDRESS) {
                WALLET_ID.transfer(feeAmount);
            } else {
                ERC20(_token).transfer(WALLET_ID, feeAmount);
            }
        }
    }
}
