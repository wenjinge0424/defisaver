pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./StaticV2.sol";

contract ISubscriptionsV2 is StaticV2 {

    function getOwner(uint _cdpId) external view returns(address);
    function getSubscribedInfo(uint _cdpId) public view returns(bool, uint128, uint128, uint128, uint128, address, uint coll, uint debt);
    function getCdpHolder(uint _cdpId) public view returns (bool subsribed, CdpHolder memory);
}
