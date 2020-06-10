pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../exchange/SaverExchangeCore.sol";

contract ExchangeDataParser {
     function decodeExchangeData(
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (address[3] memory, uint[5] memory, bytes memory) {
        return (
         [exchangeData.srcAddr, exchangeData.destAddr, exchangeData.exchangeAddr],
         [exchangeData.srcAmount, exchangeData.destAmount, exchangeData.minPrice, exchangeData.price0x, uint256(exchangeData.exchangeType)],
         exchangeData.callData
        );
    }

    function encodeExchangeData(
        address[3] memory exAddr, uint[5] memory exNum, bytes memory callData
    ) internal pure returns (SaverExchangeCore.ExchangeData memory) {
        return SaverExchangeCore.ExchangeData({
            srcAddr: exAddr[0],
            destAddr: exAddr[1],
            srcAmount: exNum[0],
            destAmount: exNum[1],
            minPrice: exNum[2],
            exchangeType: SaverExchangeCore.ExchangeType(exNum[4]),
            exchangeAddr: exAddr[2],
            callData: callData,
            price0x: exNum[3]
        });
    }
}
