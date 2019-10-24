pragma solidity ^0.5.0;

// TODO: better handle if user transfers CDP
interface ISubscriptions {

    enum Method { Boost, Repay }

    function canCall(Method _method, uint _cdpId) external view returns(bool);
    function getOwner(uint _cdpId) external view returns(address);
    function ratioGoodAfter(Method _method, uint _cdpId) external view returns(bool);
}
