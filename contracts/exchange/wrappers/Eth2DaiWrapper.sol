pragma solidity ^0.5.0;

import "../../interfaces/ERC20.sol";
import "../../interfaces/KyberNetworkProxyInterface.sol";
import "../../interfaces/ExchangeInterface.sol";
import "../../interfaces/Eth2DaiInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSMath.sol";
import "../../constants/ConstantAddresses.sol";

contract Eth2DaiWrapper is ExchangeInterface, DSMath, ConstantAddresses {


    function swapEtherToToken(uint _ethAmount, address _tokenAddress, uint _maxAmount) external payable returns(uint, uint) {
        require(ERC20(WETH_ADDRESS).approve(OTC_ADDRESS, _ethAmount));
        TokenInterface(WETH_ADDRESS).deposit.value(_ethAmount)();

        uint daiBought = Eth2DaiInterface(OTC_ADDRESS).sellAllAmount(ERC20(WETH_ADDRESS), _ethAmount,
                 ERC20(_tokenAddress), 0);

        ERC20(_tokenAddress).transfer(msg.sender, daiBought);

        return (daiBought, 0);
    }

    function swapTokenToEther(address _tokenAddress, uint _amount, uint _maxAmount) external returns(uint) {
        require(ERC20(_tokenAddress).approve(OTC_ADDRESS, _amount));

        uint ethBought = Eth2DaiInterface(OTC_ADDRESS).sellAllAmount(ERC20(_tokenAddress), _amount,
         ERC20(WETH_ADDRESS), 0);

        TokenInterface(WETH_ADDRESS).withdraw(ethBought);

        msg.sender.transfer(ethBought);

        return ethBought;
    }

    function getExpectedRate(address _src, address _dest, uint _srcQty) public view returns (uint) {
        if(_src == KYBER_ETH_ADDRESS) {
            return wdiv(Eth2DaiInterface(OTC_ADDRESS).getBuyAmount(ERC20(_dest), ERC20(WETH_ADDRESS), _srcQty), _srcQty);
        } else if (_dest == KYBER_ETH_ADDRESS) {
            return wdiv(Eth2DaiInterface(OTC_ADDRESS).getBuyAmount(ERC20(WETH_ADDRESS), ERC20(_src), _srcQty), _srcQty);
        }
    }

    function() payable external {
    }
}
