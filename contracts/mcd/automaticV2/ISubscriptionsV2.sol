pragma solidity ^0.5.0;

import "./StaticV2.sol";

contract ISubscriptionsV2 is StaticV2 {

    function canCall(Method _method, uint _cdpId) external view returns(bool, uint);
    function getOwner(uint _cdpId) external view returns(address);
    function ratioGoodAfter(Method _method, uint _cdpId) external view returns(bool, uint);
    function getRatio(uint _cdpId) public view returns (uint);
}
