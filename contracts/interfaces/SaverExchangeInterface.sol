pragma solidity ^0.5.0;


contract SaverExchangeInterface {
    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        uint256 _exchangeType
    ) public view returns (address, uint256);
}
