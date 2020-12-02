pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../savings/dydx/ISoloMargin.sol";
import "../../utils/SafeERC20.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSProxy.sol";
import "../AaveHelperV2.sol";
import "../../auth/AdminAuth.sol";
import "../../exchangeV3/DFSExchangeData.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiverV2 is AaveHelperV2, AdminAuth, DFSExchangeData {

    using SafeERC20 for ERC20;

    address public constant AAVE_SAVER_PROXY = 0xCab7ce9148499E0dD8228c3c8cDb9B56Ac2bb57a;
    address public constant AAVE_BASIC_PROXY = 0xd042D4E9B4186c545648c7FfFe87125c976D110B;
    address public constant AETH_ADDRESS = 0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04;

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        (
            bytes memory exchangeDataBytes,
            address market,
            uint256 rateMode,
            uint256 gasCost,
            bool isRepay,
            uint256 ethAmount,
            uint256 txValue,
            address user,
            address proxy
        )
        = abi.decode(data, (bytes,address,uint256,uint256,bool,uint256,uint256,address,address));

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);
        
        // deposit eth on behalf of proxy
        DSProxy(payable(proxy)).execute{value: ethAmount}(AAVE_BASIC_PROXY, abi.encodeWithSignature("deposit(address,address,uint256)", market, ETH_ADDR, ethAmount));
        
        bytes memory functionData = packFunctionCall(market, exchangeDataBytes, rateMode, gasCost, isRepay);
        DSProxy(payable(proxy)).execute{value: txValue}(AAVE_SAVER_PROXY, functionData);

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(AAVE_BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256)", market, ETH_ADDR, ethAmount));

        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    function packFunctionCall(address _market, bytes memory _exchangeDataBytes, uint256 _rateMode, uint256 _gasCost, bool _isRepay) internal returns (bytes memory) {
        ExchangeData memory exData = unpackExchangeData(_exchangeDataBytes);

        bytes memory functionData;

        if (_isRepay) {
            functionData = abi.encodeWithSignature("repay(address,(address,address,uint256,uint256,uint256,address,address,bytes,uint256),uint256,uint256)", _market, exData, _rateMode, _gasCost);
        } else {
            functionData = abi.encodeWithSignature("boost(address,(address,address,uint256,uint256,uint256,address,address,bytes,uint256),uint256,uint256)", _market, exData, _rateMode, _gasCost);
        }

        return functionData;
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external payable {
        // deposit eth and get weth 
        if (msg.sender == owner) {
            TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        }
    }
}