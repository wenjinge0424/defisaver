pragma solidity ^0.6.0;

import "../../interfaces/ExchangeInterface.sol";
import "../../interfaces/Eth2DaiInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/TokenInterface.sol";
import "../../constants/ConstantAddresses.sol";
import "../../DS/DSMath.sol";

contract OasisTradeWrapper is DSMath, ConstantAddresses, ExchangeInterface {

    function swapEtherToToken(uint _ethAmount, address _tokenAddress, uint _maxAmount) external override payable returns(uint, uint) {
        require(ERC20(WETH_ADDRESS).approve(OTC_ADDRESS, _ethAmount));
        TokenInterface(WETH_ADDRESS).deposit{value: _ethAmount}();

        uint daiBought = Eth2DaiInterface(OTC_ADDRESS).sellAllAmount(ERC20(WETH_ADDRESS), _ethAmount,
                 ERC20(_tokenAddress), 0);

        ERC20(_tokenAddress).transfer(msg.sender, daiBought);

        return (daiBought, 0);
    }

    function swapTokenToEther(address _tokenAddress, uint _amount, uint _maxAmount) external override returns(uint) {
        require(ERC20(_tokenAddress).approve(OTC_ADDRESS, _amount));

        uint ethBought = Eth2DaiInterface(OTC_ADDRESS).sellAllAmount(ERC20(_tokenAddress), _amount,
         ERC20(WETH_ADDRESS), 0);

        TokenInterface(WETH_ADDRESS).withdraw(ethBought);

        msg.sender.transfer(ethBought);

        return ethBought;
    }

    function swapTokenToToken(address _srcToken, address _dstToken, uint _amount) external override payable returns(uint) {
        require(_srcToken != KYBER_ETH_ADDRESS && _dstToken != KYBER_ETH_ADDRESS);

        require(ERC20(_srcToken).approve(OTC_ADDRESS, _amount));

        uint dstAmount = Eth2DaiInterface(OTC_ADDRESS).sellAllAmount(ERC20(_srcToken), _amount,
                 ERC20(_dstToken), 0);

        ERC20(_dstToken).transfer(msg.sender, dstAmount);

        return dstAmount;
    }

    function getExpectedRate(address _src, address _dest, uint _srcQty) public view override returns (uint) {
        if (_src == KYBER_ETH_ADDRESS) {
            return wdiv(Eth2DaiInterface(OTC_ADDRESS).getBuyAmount(ERC20(_dest), ERC20(WETH_ADDRESS), _srcQty), _srcQty);
        } else if (_dest == KYBER_ETH_ADDRESS) {
            return wdiv(Eth2DaiInterface(OTC_ADDRESS).getBuyAmount(ERC20(WETH_ADDRESS), ERC20(_src), _srcQty), _srcQty);
        } else {
            return wdiv(Eth2DaiInterface(OTC_ADDRESS).getBuyAmount(ERC20(_dest), ERC20(_src), _srcQty), _srcQty);
        }
    }

    receive() payable external {}
}
