pragma solidity ^0.6.0;

import "../../interfaces/ERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/ExchangeInterface.sol";
import "../../constants/ConstantAddresses.sol";
import "../../DS/DSMath.sol";

contract KyberWrapper is DSMath, ConstantAddresses {

    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable returns (uint) {
        ERC20 srcToken = ERC20(wethToEthAddr(_srcAddr));
        ERC20 destToken = ERC20(wethToEthAddr(_destAddr));

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);
        (, uint minRate) = kyberNetworkProxy.getExpectedRate(srcToken, destToken, _srcAmount);

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            _srcAmount,
            destToken,
            msg.sender,
            uint(-1),
            minRate,
            WALLET_ID
        );

        return destAmount;
    }

    function buy(address _srcAddr, address _destAddr, uint _destAmount) external payable returns(uint) {
        ERC20 srcToken = ERC20(wethToEthAddr(_srcAddr));
        ERC20 destToken = ERC20(wethToEthAddr(_destAddr));

        uint srcAmount = srcToken.balanceOf(address(this));

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);
        (, uint minRate) = kyberNetworkProxy.getExpectedRate(srcToken, destToken, srcAmount);

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            srcAmount,
            destToken,
            msg.sender,
            _destAmount,
            minRate,
            WALLET_ID
        );

        require(destAmount == _destAmount);

        // TODO: return leftover tokens

        uint srcAmountAfter = srcToken.balanceOf(address(this));

        return (srcAmount - srcAmountAfter);
    }

    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) public view returns (uint rate) {
        (rate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE)
            .getExpectedRate(ERC20(_srcAddr), ERC20(_destAddr), _srcAmount);
    }

    // check this if we get the same rate as the other wrappers
    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount) public view returns (uint rate) {
        (uint srcRate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE)
            .getExpectedRate(ERC20(_destAddr), ERC20(_srcAddr), _destAmount);

        uint srcAmount = wdiv(_destAmount, srcRate);

        // TODO: lower the rate a bit, beacuse of the buy/sell conversion

        (rate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE)
            .getExpectedRate(ERC20(_srcAddr), ERC20(_destAddr), srcAmount);
    }

    /// @notice Converts WETH -> Kybers Eth address
    /// @param _src Input address
    function wethToEthAddr(address _src) internal pure returns (address) {
        return _src == WETH_ADDRESS ? KYBER_ETH_ADDRESS : _src;
    }

    receive() payable external {}
}
