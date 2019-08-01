pragma solidity ^0.5.0;

import "./ERC20.sol";

//TODO: currenlty only adjusted to kyber, but should be genric interfaces for more dec. exchanges
interface ExchangeInterface {
    function swapEtherToToken (uint _ethAmount, address _tokenAddress, uint _maxAmount) payable external returns(uint, uint);
    function swapTokenToEther (address _tokenAddress, uint _amount, uint _maxAmount) external returns(uint);

    function getExpectedRate(address src, address dest, uint srcQty) external
        returns (uint expectedRate, uint slippageRate);
}
