pragma solidity ^0.5.0;


contract ProtocolInterface {
    function deposit(address _user, uint256 _amount) public;

    function withdraw(address _user, uint256 _amount) public;
}
