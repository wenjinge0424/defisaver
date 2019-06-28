pragma solidity ^0.5.0;

import "./ERC20.sol";

contract CTokenInterface is ERC20 {
    function mint(uint mintAmount) external returns (uint);
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;

    function exchangeRateCurrent() external returns (uint);
    function supplyRatePerBlock() external returns (uint);
    function borrowRatePerBlock() external returns (uint);
    function totalReserves() external returns (uint);
    function reserveFactorMantissa() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function getCash() external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
}