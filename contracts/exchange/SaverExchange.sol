pragma solidity ^0.5.0;

import "../interfaces/ExchangeInterface.sol";
import "../DS/DSMath.sol";

contract SaverExchange is DSMath {
    //KOVAN
    address public constant DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WALLET_ID = 0x54b44C6B18fc0b4A1010B21d524c338D1f8065F6;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    address public constant KYBER_WRAPPER = 0x5595930d576Aedf13945C83cE5aaD827529A1310;
    address public constant UNISWAP_WRAPPER = 0x5595930d576Aedf13945C83cE5aaD827529A1310;
    address public constant ETH2DAI_WRAPPER = 0x823cde416973a19f98Bb9C96d97F4FE6C9A7238B;


    function swapDaiToEth(uint _amount, uint _minPrice, uint _exchangeType) public {
        require(ERC20(DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount));

        uint fee = takeFee(_amount);
        _amount = sub(_amount, fee);

        address exchangeWrapper;
        uint daiEthPrice;
        (exchangeWrapper, daiEthPrice) = getBestPrice(_amount, DAI_ADDRESS, ETHER_ADDRESS, _exchangeType);

        require(wdiv(1000000000000000000, daiEthPrice) < _minPrice, "Slippage hit");

        ERC20(DAI_ADDRESS).transfer(exchangeWrapper, _amount);
        ExchangeInterface(exchangeWrapper).swapTokenToEther(DAI_ADDRESS, _amount, uint(-1));

        uint daiBalance = ERC20(DAI_ADDRESS).balanceOf(address(this));
        if (daiBalance > 0) {
            ERC20(DAI_ADDRESS).transfer(msg.sender, daiBalance);
        }

        msg.sender.transfer(address(this).balance);
    }

    function swapEthToDai(uint _amount, uint _minPrice, uint _exchangeType) public payable {
        require(msg.value >= _amount);

        address exchangeWrapper;
        uint ethDaiPrice;
        (exchangeWrapper, ethDaiPrice) = getBestPrice(_amount, ETHER_ADDRESS, DAI_ADDRESS, _exchangeType);

        require(ethDaiPrice > _minPrice, "Slippage hit");
        
        uint ethReturned;
        uint daiReturned;
        (daiReturned, ethReturned) = ExchangeInterface(exchangeWrapper).swapEtherToToken.value(_amount)(_amount, DAI_ADDRESS, uint(-1));
        
        uint fee = takeFee(daiReturned);
        daiReturned = sub(daiReturned, fee);

        ERC20(DAI_ADDRESS).transfer(msg.sender, daiReturned);

        if (ethReturned > 0) {
            msg.sender.transfer(ethReturned);
        }
    }
    

    /// @notice Returns the best estimated price from 2 exchanges
    /// @param _amount Amount of source tokens you want to exchange
    /// @param _srcToken Address of the source token
    /// @param _destToken Address of the destination token
    /// @return (address, uint) The address of the best exchange and the exchange price
    function getBestPrice(uint _amount, address _srcToken, address _destToken, uint _exchangeType) public view returns (address, uint) {
        uint expectedRateKyber;
        uint expectedRateUniswap;
        uint expectedRateEth2Dai;

        (expectedRateKyber, ) = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);
        (expectedRateUniswap, ) = ExchangeInterface(UNISWAP_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);
        // reverts on kovan
        // (expectedRateEth2Dai, ) = ExchangeInterface(ETH2DAI_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);

        if (_exchangeType == 1) {
            return (ETH2DAI_WRAPPER, expectedRateEth2Dai);
        }

        if (_exchangeType == 2) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if (_exchangeType == 3) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }

        if ((expectedRateEth2Dai >= expectedRateKyber) && (expectedRateEth2Dai >= expectedRateUniswap)) {
            return (ETH2DAI_WRAPPER, expectedRateEth2Dai);
        }

        if ((expectedRateKyber >= expectedRateUniswap) && (expectedRateKyber >= expectedRateEth2Dai)) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if ((expectedRateUniswap >= expectedRateKyber) && (expectedRateUniswap >= expectedRateEth2Dai)) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }
    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @return feeAmount Amount in Dai owner earned on the fee
    function takeFee(uint _amount) internal returns (uint feeAmount) {
        feeAmount = _amount / SERVICE_FEE;
        if (feeAmount > 0) {
            ERC20(DAI_ADDRESS).transfer(WALLET_ID, feeAmount);
        }
    }

    // receive eth from wrappers
    function() external payable {}
}