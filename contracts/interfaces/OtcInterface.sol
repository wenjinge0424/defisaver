pragma solidity ^0.5.0;


contract OtcInterface {
    function buyAllAmount(address, uint256, address, uint256) public returns (uint256);

    function getPayAmount(address, address, uint256) public view returns (uint256);

    function getBuyAmount(address, address, uint256) public view returns (uint256);
}
