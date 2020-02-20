pragma solidity ^0.5.0;

import "./ERC20.sol";


contract Eth2DaiInterface {
    function getBuyAmount(ERC20 tokenToBuy, ERC20 tokenToPay, uint256 amountToPay)
        external
        view
        returns (uint256 amountBought);

    function getPayAmount(ERC20 tokenToPay, ERC20 tokenToBuy, uint256 amountToBuy)
        public
        view
        returns (uint256 amountPaid);

    function sellAllAmount(ERC20 pay_gem, uint256 pay_amt, ERC20 buy_gem, uint256 min_fill_amount)
        public
        returns (uint256 fill_amt);

    function buyAllAmount(ERC20 buy_gem, uint256 buy_amt, ERC20 pay_gem, uint256 max_fill_amount)
        public
        returns (uint256 fill_amt);
}
