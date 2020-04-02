pragma solidity ^0.5.0;

import "../CompoundSaverProxy.sol";
import "../../mcd/Discount.sol";


contract CompoundFlashSaverProxy is CompoundSaverProxy {

    // TODO: don't use msg.value
    function flashRepay(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData
    ) public payable {
        // repay(_data, _addrData, _callData);
    }

     function flashBoost(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData
    ) public payable {
        // boost(_data, _addrData, _callData);
    }

}
