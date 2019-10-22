pragma solidity ^0.5.0;

// TODO: better handle if user transfers CDP
contract Subscriptions {

    struct CdpHolder {
        uint32 minRatio;
        uint32 maxRatio;
        uint32 optimalRatioBoost;
        uint32 optimalRatioRepay;
        address owner;
    }

    struct SubPosition {
        uint arrPos;
        bool subscribed;
    }

    CdpHolder[] public subscribers;
    mapping (uint => SubPosition) public subscribersPos;

    address public owner;

    event Subscribed(address indexed owner, uint cdpId);
    event Unsubscribed(address indexed owner, uint cdpId);
    event Updated(address indexed owner, uint cdpId);

    constructor() public {
        owner = msg.sender;
    }

    function subscribe(uint _cdpId, uint32 _minRatio, uint32 _maxRatio, uint32 _optimalBoost, uint32 _optimalRepay) external {
        require(isOwner(msg.sender, _cdpId), "Must be called by Cdp owner");

        SubPosition storage subInfo = subscribersPos[_cdpId];

        CdpHolder memory subscription = CdpHolder({
                minRatio: _minRatio,
                maxRatio: _maxRatio,
                optimalRatioBoost: _optimalBoost,
                optimalRatioRepay: _optimalRepay,
                owner: msg.sender
            });

        if (subInfo.subscribed) {
            subscribers[subInfo.arrPos] = subscription;

            emit Updated(msg.sender, _cdpId);
        } else {
            subscribers.push(subscription);

            subInfo.arrPos = subscribers.length - 1;
            subInfo.subscribed = true;

            emit Subscribed(msg.sender, _cdpId);
        }
    }


    function unsubscribe(uint _cdpId) external {
        require(isOwner(msg.sender, _cdpId), "Must be called by Cdp owner");
        require(subscribers.length > 0, "Must have subscribers in the list");

        SubPosition storage subInfo = subscribersPos[_cdpId];

        require(subInfo.subscribed, "Must first be subscribed");

        subscribers[subInfo.arrPos] = subscribers[subscribers.length - 1];
        delete subscribers[subscribers.length - 1];


    }

    function isOwner(address _owner, uint _cdpId) internal returns (bool) {

    }

    function checkParams() internal returns (bool) {

    }
}
