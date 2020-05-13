pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/GasTokenInterface.sol";
import "./SaverExchangeCore.sol";
import "../DS/DSMath.sol";
import "../loggers/ExchangeLogger.sol";

contract SaverExchange is SaverExchangeCore, DSMath {

    uint256 public constant SERVICE_FEE = 800; // 0.125% Fee

    // solhint-disable-next-line const-name-snakecase
    ExchangeLogger public constant logger = ExchangeLogger(0xf7CE9aa00bc4f4c413E4B4a613e889C1Ad01883e);
    GasTokenInterface gasToken = GasTokenInterface(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    address public owner;
    uint public burnAmount;

    constructor() public {
        owner = msg.sender;
        burnAmount = 10;
    }

    /// @notice Takes a src amount of tokens and converts it into the dest token
    /// @dev Takes fee from the _srcAmount before the exchange
    /// @param exData [srcAddr, destAddr, srcAmount, destAmount, minPrice, exchangeType, exchangeAddr, callData, price0x]
    function sell(ExchangeData memory exData) public payable {
        if (gasToken.balanceOf(address(this)) >= burnAmount) {
            gasToken.free(burnAmount);
        }

        // transfer tokens from the user
        pullTokens(exData.srcAddr, exData.srcAmount);

        // take fee
        uint dfsFee = takeFee(exData.srcAmount, exData.srcAddr);
        exData.srcAmount = sub(exData.srcAmount, dfsFee);

        // Perform the exchange
        (address wrapper, uint destAmount) = _sell(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr, msg.sender);

        // log the event
        logger.logSwap(exData.srcAddr, exData.destAddr, exData.srcAmount, destAmount, wrapper);
    }

    /// @notice Takes a dest amount of tokens and converts it from the src token
    /// @dev Send always more than needed for the swap, extra will be returned
    /// @param exData [srcAddr, destAddr, srcAmount, destAmount, minPrice, exchangeType, exchangeAddr, callData, price0x]
    function buy(ExchangeData memory exData) public payable {
        if (gasToken.balanceOf(address(this)) >= burnAmount) {
            gasToken.free(burnAmount);
        }

        // transfer tokens from the user
        pullTokens(exData.srcAddr, exData.srcAmount);

        uint dfsFee = takeFee(exData.srcAmount, exData.srcAddr);
        exData.srcAmount = sub(exData.srcAmount, dfsFee);

        // Perform the exchange
        (address wrapper, uint srcAmount) = _buy(exData);

        // send back any leftover ether or tokens
        sendLeftover(exData.srcAddr, exData.destAddr, msg.sender);

        // log the event
        logger.logSwap(exData.srcAddr, exData.destAddr, srcAmount, exData.destAmount, wrapper);
    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @param _token Address of the token
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

    /// @notice Changes the amount of gas token we burn for each call
    /// @dev Only callable by the owner
    /// @param _newBurnAmount New amount of gas tokens to be burned
    function changeBurnAmount(uint _newBurnAmount) public {
        require(owner == msg.sender);

        burnAmount = _newBurnAmount;
    }
}
