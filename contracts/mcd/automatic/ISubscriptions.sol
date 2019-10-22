pragma solidity ^0.5.0;

// TODO: better handle if user transfers CDP
contract ISubscriptions {

    enum Method { Boost, Repay }

    function canCall(Method _method, uint _cdpId) public view returns(bool);
    function getOwner(uint _cdpId) public view returns(address);
    function ratioGoodAfter(Method _method, uint _cdpId) public view returns(bool);
}
