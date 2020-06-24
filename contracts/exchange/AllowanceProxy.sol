pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../auth/AdminAuth.sol";
import "./SaverExchange.sol";

contract AllowanceProxy is AdminAuth {

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // TODO: Real saver exchange address
    SaverExchange saverExchange = SaverExchange(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function callSell(SaverExchangeCore.ExchangeData memory exData) public payable {
        pullAndSendTokens(exData.srcAddr, exData.srcAmount);

        saverExchange.sell{value: msg.value}(exData);
    }

    function callBuy(SaverExchangeCore.ExchangeData memory exData) public payable {
        pullAndSendTokens(exData.srcAddr, exData.srcAmount);

        saverExchange.buy{value: msg.value}(exData);
    }

    function pullAndSendTokens(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount, "msg.value smaller than amount");
        } else {
            require(
                ERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount),
                "Not able to withdraw wanted amount"
            );

            ERC20(_tokenAddr).transfer(address(saverExchange), _amount);
        }
    }
}
