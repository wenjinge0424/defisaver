pragma solidity ^0.6.0;

abstract contract ILoanShifter {
    function getLoanAmount(uint, address) public view virtual returns(uint);
    function open() public virtual;
    function close() public virtual;
}
