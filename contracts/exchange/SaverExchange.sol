pragma solidity ^0.5.0;

import "../interfaces/ExchangeInterface.sol";
import "../DS/DSMath.sol";
import "../constants/ConstantAddresses.sol";

contract SaverExchange is DSMath, ConstantAddresses {

    uint public constant SERVICE_FEE = 800; // 0.125% Fee

    function swapDaiToEth(uint _amount, uint _minPrice, uint _exchangeType) public {
        require(ERC20(MAKER_DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount));

        uint fee = takeFee(_amount);
        _amount = sub(_amount, fee);

        address exchangeWrapper;
        uint daiEthPrice;
        (exchangeWrapper, daiEthPrice) = getBestPrice(_amount, MAKER_DAI_ADDRESS, KYBER_ETH_ADDRESS, _exchangeType);

        require(daiEthPrice > _minPrice, "Slippage hit");

        ERC20(MAKER_DAI_ADDRESS).transfer(exchangeWrapper, _amount);
        ExchangeInterface(exchangeWrapper).swapTokenToEther(MAKER_DAI_ADDRESS, _amount, uint(-1));

        uint daiBalance = ERC20(MAKER_DAI_ADDRESS).balanceOf(address(this));
        if (daiBalance > 0) {
            ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, daiBalance);
        }

        msg.sender.transfer(address(this).balance);
    }

    function swapEthToDai(uint _amount, uint _minPrice, uint _exchangeType) public payable {
        require(msg.value >= _amount);

        address exchangeWrapper;
        uint ethDaiPrice;
        (exchangeWrapper, ethDaiPrice) = getBestPrice(_amount, KYBER_ETH_ADDRESS, MAKER_DAI_ADDRESS, _exchangeType);

        require(ethDaiPrice > _minPrice, "Slippage hit");

        uint ethReturned;
        uint daiReturned;
        (daiReturned, ethReturned) = ExchangeInterface(exchangeWrapper).swapEtherToToken.value(_amount)(_amount, MAKER_DAI_ADDRESS, uint(-1));

        uint fee = takeFee(daiReturned);
        daiReturned = sub(daiReturned, fee);

        ERC20(MAKER_DAI_ADDRESS).transfer(msg.sender, daiReturned);

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
        // no deployment on kovan
        // (expectedRateUniswap, ) = ExchangeInterface(UNISWAP_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);
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
            ERC20(MAKER_DAI_ADDRESS).transfer(WALLET_ID, feeAmount);
        }
    }

    // receive eth from wrappers
    function() external payable {}
}
