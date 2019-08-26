pragma solidity ^0.5.0;

contract Console {

    mapping (address => string[]) public logs;

    function log(string calldata _desc) external {
        logs[msg.sender].push(_desc);
    }

    function getLog(address _contractAddr, uint _pos) view public returns (string memory) {
        return logs[_contractAddr][_pos];
    }

    function getLastLog(address _contractAddr) view public returns (string memory) {
        return logs[_contractAddr][logs[_contractAddr].length - 1];
    }
}
