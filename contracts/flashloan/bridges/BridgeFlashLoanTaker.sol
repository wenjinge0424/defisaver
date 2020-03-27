pragma solidity ^0.5.0;

import "../aave/ILendingPool.sol";

contract BridgeFlashLoanTaker {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    function compound2Maker(
        uint _cdpId,
        uint _collAmount,
        uint _debtAmount,
        address _cCollateralAddr,
        address _cDebtAddr
    ) external {

        // bytes memory paramsData = abi.encode(_data, _joinAddr, _exchangeAddress, _callData, false);

        // lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, AAVE_DAI_ADDRESS, loanAmount, paramsData);
    }

    function maker2Compound(uint _cdpId) external {

    }
}
