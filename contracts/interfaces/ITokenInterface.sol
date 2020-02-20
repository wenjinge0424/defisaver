pragma solidity ^0.5.0;

import "./ERC20.sol";


contract ITokenInterface is ERC20 {
    function assetBalanceOf(address _owner) public view returns (uint256);

    function mint(address receiver, uint256 depositAmount) external returns (uint256 mintAmount);

    function burn(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function tokenPrice() public view returns (uint256 price);
}
