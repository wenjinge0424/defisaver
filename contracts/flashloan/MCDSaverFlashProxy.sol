pragma solidity ^0.5.0;

import "../mcd/saver_proxy/MCDSaverProxy.sol";

contract IDaiToken {
    function flashBorrowToken(
        uint256 borrowAmount,
        address borrower,
        address target,
        string calldata signature,
        bytes calldata data
    )
        external
        payable;
}

contract MCDSaverFlashProxy is MCDSaverProxy {

    IDaiToken public constant IDAI = IDaiToken(IDAI_ADDRESS);
    Manager public constant manager = Manager(MANAGER_ADDRESS);

    function getLoan(
        uint _cdpId,
        address _joinAddr,
        uint _amount,
        uint _minPrice,
        uint _exchangeType,
        uint _gasCost,
        bool isRepay
    ) external {
        uint maxDebt = getMaxDebt(_cdpId, manager.ilks(_cdpId));

        uint loanAmount = sub(_amount, maxDebt);

        if (isRepay) {
            IDAI.flashBorrowToken(loanAmount, address(this), address(this), "",
                abi.encodeWithSignature('repayWithLoan(uint256,address,uint256,uint256,uint256,uint256,uint256,bool)',
                _cdpId, _joinAddr, _amount, loanAmount, _minPrice, _exchangeType, _gasCost, isRepay)
            );
        } else {
            IDAI.flashBorrowToken(loanAmount, address(this), address(this), "",
                abi.encodeWithSignature('repayWithLoan(uint256,address,uint256,uint256,uint256,uint256,uint256,bool)',
                _cdpId, _joinAddr, _amount, loanAmount, _minPrice, _exchangeType, _gasCost, isRepay)
            );
        }
    }

    function actionWithLoan(
        uint _cdpId,
        address _joinAddr,
        uint _amount,
        uint _loanAmount,
        uint _minPrice,
        uint _exchangeType,
        uint _gasCost,
        bool isRepay
    ) internal {

        // payback the CDP debt with loan amount
        address owner = getOwner(manager, _cdpId);
        paybackDebt(_cdpId, manager.ilks(_cdpId), _loanAmount, owner);

        if (isRepay) {
            repay(_cdpId, _joinAddr, _amount, _minPrice, _exchangeType, _gasCost);
        } else {
            boost(_cdpId, _joinAddr, _amount, _minPrice, _exchangeType, _gasCost);
        }

        // repay the flash loan
        drawDai(_cdpId, manager.ilks(_cdpId), _loanAmount);
        ERC20(DAI_ADDRESS).transfer(address(IDAI), _loanAmount);
    }

}
