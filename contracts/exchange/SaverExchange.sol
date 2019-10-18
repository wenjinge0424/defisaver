pragma solidity ^0.5.0;

import "../interfaces/ExchangeInterface.sol";
import "../DS/DSMath.sol";
import "../constants/ConstantAddresses.sol";

contract SaverExchange is DSMath, ConstantAddresses {

    uint public constant SERVICE_FEE = 800; // 0.125% Fee

    function swapTokenToToken(address _src, address _dest, uint _amount, uint _minPrice, uint _exchangeType) public payable {
        if (_src == KYBER_ETH_ADDRESS) {
            require(msg.value >= _amount);
            // return user if he sent too much
            msg.sender.transfer(sub(msg.value, _amount));
        } else {
            require(ERC20(_src).transferFrom(msg.sender, address(this), _amount));
        }

        uint fee = takeFee(_amount, _src);
        _amount = sub(_amount, fee);

        address wrapper;
        uint price;
        (wrapper, price) = getBestPrice(_amount, _src, _dest, _exchangeType);

        require(price > _minPrice, "Slippage hit");

        uint tokensReturned;
        if (_src == KYBER_ETH_ADDRESS) {
            (tokensReturned,) = ExchangeInterface(wrapper).swapEtherToToken.value(_amount)(_amount, _dest, uint(-1));
        } else {
            ERC20(_src).transfer(wrapper, _amount);

            if (_dest == KYBER_ETH_ADDRESS) {
                tokensReturned = ExchangeInterface(wrapper).swapTokenToEther(_src, _amount, uint(-1));
            } else {
                tokensReturned = ExchangeInterface(wrapper).swapTokenToToken(_src, _dest, _amount);
            }
        }

        if (_dest == KYBER_ETH_ADDRESS) {
            msg.sender.transfer(tokensReturned);
        } else {
            ERC20(_dest).transfer(msg.sender, tokensReturned);
        }
    }


    // legacy ------------------------------------------------------------

    function swapDaiToEth(uint _amount, uint _minPrice, uint _exchangeType) public {
        require(ERC20(MAKER_DAI_ADDRESS).transferFrom(msg.sender, address(this), _amount));

        uint fee = takeFee(_amount, MAKER_DAI_ADDRESS);
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

        uint fee = takeFee(daiReturned, MAKER_DAI_ADDRESS);
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
        uint expectedRateOasis;

        (expectedRateKyber, ) = ExchangeInterface(KYBER_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);
        (expectedRateOasis, ) = ExchangeInterface(OASIS_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);
        // no deployment on kovan
        // (expectedRateUniswap, ) = ExchangeInterface(UNISWAP_WRAPPER).getExpectedRate(_srcToken, _destToken, _amount);

        if (_exchangeType == 1) {
            return (OASIS_WRAPPER, expectedRateOasis);
        }

        if (_exchangeType == 2) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if (_exchangeType == 3) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }

        if ((expectedRateKyber >= expectedRateUniswap) && (expectedRateKyber >= expectedRateOasis)) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if ((expectedRateOasis >= expectedRateKyber) && (expectedRateOasis >= expectedRateUniswap)) {
            return (ETH2DAI_WRAPPER, expectedRateOasis);
        }

        if ((expectedRateUniswap >= expectedRateKyber) && (expectedRateUniswap >= expectedRateOasis)) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }
    }

    /// @notice Takes a feePercentage and sends it to wallet
    /// @param _amount Dai amount of the whole trade
    /// @return feeAmount Amount in Dai owner earned on the fee
    function takeFee(uint _amount, address _token) internal returns (uint feeAmount) {
        feeAmount = _amount / SERVICE_FEE;
        if (feeAmount > 0) {
            if (_token == KYBER_ETH_ADDRESS) {
                WALLET_ID.transfer(feeAmount);
            } else {
                ERC20(_token).transfer(WALLET_ID, feeAmount);
            }
        }
    }

    // receive eth from wrappers
    function() external payable {}
}
