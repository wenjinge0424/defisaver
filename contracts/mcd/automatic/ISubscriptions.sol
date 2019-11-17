pragma solidity ^0.5.0;

import "./Static.sol";

contract ISubscriptions is Static {

    function canCall(Method _method, uint _cdpId) external view returns(bool, uint);
    function getOwner(uint _cdpId) external view returns(address);
    function ratioGoodAfter(Method _method, uint _cdpId) external view returns(bool, uint);
    function getRatio(uint _cdpId) public view returns (uint);
}
