pragma solidity ^0.5.0;


contract MCDCloseSubscribers {

    // struct ClosePosition {
    //     uint minProfit;
    //     uint maxProfit;
    //     uint cdpId;
    // }

    // mapping (uint => ClosePosition) public closePositions;
    // uint[] public subscribedCdps;

    function subscribe(uint _cdpId, uint _minProfit, uint _maxProfit) public {
        // require(isOwner(msg.sender, _cdpId), "Must be the owner of the CDP");

    //     closePositions[_cdpId] = ClosePosition({
    //         minProfit: _minProfit,
    //         maxProfit: _maxProfit,
    //         cdpId: _cdpId
    //     });
    // }

    function unsubscribe(uint _cdpId) public {
        // require(isOwner(msg.sender, _cdpId), "Must be the owner of the CDP");
    }

    // function canCall() public returns (bool) {

    // }

    /// @dev Checks if the _owner is the owner of the CDP
    // function isOwner(address _owner, uint _cdpId) internal view returns (bool) {
    //     return manager.owns(_cdpId) == _owner;
    // }
}
