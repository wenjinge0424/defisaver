pragma solidity ^0.5.0;


contract Osm {
    mapping(address => uint256) public bud;
    
    function peep() external view returns (bytes32, bool);
}
