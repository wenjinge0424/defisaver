pragma solidity ^0.5.0;


contract DSGuard {
    function canCall(address src_, address dst_, bytes4 sig) public view returns (bool);

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public;
    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public;

    function permit(address src, address dst, bytes32 sig) public;
    function forbid(address src, address dst, bytes32 sig) public;

}


contract DSGuardFactory {
    function newGuard() public returns (DSGuard guard);
}
