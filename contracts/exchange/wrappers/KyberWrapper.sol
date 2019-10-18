pragma solidity ^0.5.0;

import "../../interfaces/ERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/ExchangeInterface.sol";
import "../../constants/ConstantAddresses.sol";


contract KyberWrapper is ExchangeInterface, ConstantAddresses {

    function swapTokenToToken(address _src, address _dest, uint _amount) external payable returns(uint) {
        require(_src != KYBER_ETH_ADDRESS && _dest != KYBER_ETH_ADDRESS);

        uint minRate;
        uint destAmount;
        ERC20 SRC_TOKEN = ERC20(_src);
        ERC20 DEST_TOKEN = ERC20(_dest);

        KyberNetworkProxyInterface _kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        (, minRate) = _kyberNetworkProxy.getExpectedRate(SRC_TOKEN, DEST_TOKEN, _amount);

        // Mitigate ERC20 Approve front-running attack, by initially setting, allowance to 0
        require(SRC_TOKEN.approve(address(_kyberNetworkProxy), 0));
        // Approve tokens so network can take them during the swap
        SRC_TOKEN.approve(address(_kyberNetworkProxy), _amount);

        destAmount = _kyberNetworkProxy.trade(
            SRC_TOKEN,
            _amount,
            DEST_TOKEN,
            msg.sender,
            uint(-1),
            minRate,
            WALLET_ID
        );


        return destAmount;
    }


    function swapEtherToToken(uint _ethAmount, address _tokenAddress, uint _maxAmount) external payable returns(uint, uint) {
        uint minRate;
        ERC20 ETH_TOKEN_ADDRESS = ERC20(KYBER_ETH_ADDRESS);
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

    function swapTokenToEther(address _tokenAddress, uint _amount, uint _maxAmount) external returns(uint) {
        uint minRate;
        ERC20 ETH_TOKEN_ADDRESS = ERC20(KYBER_ETH_ADDRESS);
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

    function getExpectedRate(address _src, address _dest, uint _srcQty) public view returns (uint, uint) {
        return KyberNetworkProxyInterface(KYBER_INTERFACE).getExpectedRate(ERC20(_src), ERC20(_dest), _srcQty);
    }

    function() payable external {
    }
}
