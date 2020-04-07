pragma solidity ^0.5.0;

import "../../flashloan/aave/ILendingPool.sol";
import "../../interfaces/CTokenInterface.sol";
import "../CompoundSaverHelper.sol";

contract CompoundImportTaker is CompoundSaverHelper{

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_IMPORT = 0x0D5Ec207D7B29525Cc25963347903958C98a66d3;

    function importLoan(address _cCollateralToken, address _cBorrowToken) external {
        // get borrow amount
        uint loanAmount = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(address(this));

        bytes memory paramsData = abi.encode(_cCollateralToken, _cBorrowToken, msg.sender);

        // FL with Aave
        lendingPool.flashLoan(COMPOUND_IMPORT, getUnderlyingAddr(_cBorrowToken), loanAmount, paramsData);
    }
}
