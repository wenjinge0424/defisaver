pragma solidity ^0.6.0;

import "./Static.sol";

abstract contract ISubscriptions is Static {

    function canCall(Method _method, uint _cdpId) external virtual view returns(bool, uint);
    function getOwner(uint _cdpId) external virtual view returns(address);
    function ratioGoodAfter(Method _method, uint _cdpId) external virtual view returns(bool, uint);
    function getRatio(uint _cdpId) public view virtual returns (uint);
}
