pragma solidity 0.5.0;

contract OtcInterface {
    function buyAllAmount(address, uint, address, uint) public returns (uint);

    function getPayAmount(address, address, uint) public view returns (uint);
    function getBuyAmount(address, address, uint) public view returns (uint);
}