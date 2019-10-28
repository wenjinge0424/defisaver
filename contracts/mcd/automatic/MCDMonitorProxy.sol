pragma solidity ^0.5.0;

import "../../interfaces/DSProxyInterface.sol";

contract MCDMonitorProxy {

    // mainnet
    // uint public CHANGE_PERIOD = 15 days;
    // testing
    uint public CHANGE_PERIOD = 0;

    address public monitor;
    address public owner;
    address public newMonitor;
    uint public changeRequestedTimestamp;
    bool public MONITOR_SETTED_FIRST_TIME = false;

    mapping(address => bool) public allowed;

    // if someone who is allowed become malicious, owner can't be changed
    modifier onlyAllowed() {
        require(allowed[msg.sender] || msg.sender == owner);
        _;
    }

    modifier onlyMonitor() {
        require (msg.sender == monitor);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setMonitor(address _monitor) public onlyAllowed {
        require(!MONITOR_SETTED_FIRST_TIME);
        monitor = _monitor;
        MONITOR_SETTED_FIRST_TIME = true;
    }

    function callExecute(address _owner, address _saverProxy, bytes memory data) public onlyMonitor {
        // execute reverts if calling specific method fails
        DSProxyInterface(_owner).execute(_saverProxy, data);
    }

    function changeMonitor(address _newMonitor) public onlyAllowed {
        changeRequestedTimestamp = now;
        newMonitor = _newMonitor;
    }

    function cancelMonitorChange() public onlyAllowed {
        changeRequestedTimestamp = 0;
        newMonitor = address(0);
    }

    function confirmNewMonitor() public {
        require((changeRequestedTimestamp + CHANGE_PERIOD) < now);
        require(changeRequestedTimestamp != 0);

        monitor = newMonitor;
        newMonitor = address(0);
        changeRequestedTimestamp = 0;
    }

    function addAllowed(address _user) public onlyAllowed {
        allowed[_user] = true;
    }

    function removeAllowed(address _user) public onlyAllowed {
        allowed[_user] = false;
    }
}
