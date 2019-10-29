pragma solidity ^0.5.0;

contract SaverExchangeInterface {
    function getBestPrice(uint _amount, address _srcToken, address _destToken, uint _exchangeType) public view returns (address, uint);
}
