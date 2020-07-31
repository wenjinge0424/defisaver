pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../savings/dydx/ISoloMargin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/TokenInterface.sol";

// weth->eth 
// deposit eth for users proxy
// borrow users token from proxy
// repay on behalf of user
// pull user supply
// deposit supply to users proxy
// take eth amount from supply (if needed more, borrow it?)
// return eth to sender

/// @title Import Aave position from account to wallet
contract AaveImport {

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(
            TokenInterface(WETH_ADDRESS).balanceOf(address(this))
        );


        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        IERC20(WETH_ADDRESS).transfer(sender, IERC20(WETH_ADDRESS).balanceOf(address(this)));
    }
}