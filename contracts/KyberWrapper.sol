pragma solidity ^0.5.0;

import "./interfaces/ERC20.sol";
import "./interfaces/KyberNetworkProxyInterface.sol";
import "./interfaces/ExchangeInterface.sol";

contract KyberWrapper is ExchangeInterface {

    // Kovan
    address constant KYBER_INTERFACE = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D;
    address constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address constant WALLET_ID = 0x54b44C6B18fc0b4A1010B21d524c338D1f8065F6;

    function swapEtherToToken (uint _ethAmount, address _tokenAddress, uint _maxAmount) external payable returns(uint, uint) {
        uint minRate;
        ERC20 ETH_TOKEN_ADDRESS = ERC20(ETHER_ADDRESS);
        ERC20 token = ERC20(_tokenAddress);

        KyberNetworkProxyInterface _kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        (, minRate) = _kyberNetworkProxy.getExpectedRate(ETH_TOKEN_ADDRESS, token, _ethAmount);

        uint destAmount = _kyberNetworkProxy.trade.value(_ethAmount)(
            ETH_TOKEN_ADDRESS,
            _ethAmount,
            token,
            msg.sender,
            _maxAmount,
            minRate,
            WALLET_ID
        );

        uint balance = address(this).balance;

        msg.sender.transfer(balance);

        return (destAmount, balance);
    }

    function swapTokenToEther (address _tokenAddress, uint _amount, uint _maxAmount) external returns(uint) {
        uint minRate;
        ERC20 ETH_TOKEN_ADDRESS = ERC20(ETHER_ADDRESS);
        ERC20 token = ERC20(_tokenAddress);

        KyberNetworkProxyInterface _kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        (, minRate) = _kyberNetworkProxy.getExpectedRate(token, ETH_TOKEN_ADDRESS, _amount);

        // Mitigate ERC20 Approve front-running attack, by initially setting, allowance to 0
        require(token.approve(address(_kyberNetworkProxy), 0));

        // Approve tokens so network can take them during the swap
        token.approve(address(_kyberNetworkProxy), _amount);

        uint destAmount = _kyberNetworkProxy.trade(
            token,
            _amount,
            ETH_TOKEN_ADDRESS,
            msg.sender,
            _maxAmount,
            minRate,
            WALLET_ID
        );

        return destAmount;
    }

    function getExpectedRate(address _src, address _dest, uint _srcQty) public returns (uint, uint) {
        return KyberNetworkProxyInterface(KYBER_INTERFACE).getExpectedRate(ERC20(_src), ERC20(_dest), _srcQty);
    }

    function() payable external {
    }
}
