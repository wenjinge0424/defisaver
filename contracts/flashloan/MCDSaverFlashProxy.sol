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

contract MCDFlashLoanTaker is MCDSaverProxy {
    address public constant MCD_SAVER_FLASH_PROXY = 0x4b3FB6725c5B57377b6a140f71bE50649AbdE721;

    Manager public constant manager = Manager(MANAGER_ADDRESS);
    IDaiToken public constant IDAI = IDaiToken(NEW_IDAI_ADDRESS);

    enum ActionTypes { Repay, Boost }

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

        uint debtAmount = _amount;

        if (isRepay) {
            uint ethPrice = getPrice(ETH_ILK);
            debtAmount = rmul(_amount, add(ethPrice, div(ethPrice, 10)));
        }

        uint loanAmount = sub(debtAmount, maxDebt);

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_PROXY, 1);

        if (isRepay) {
            IDAI.flashBorrowToken(loanAmount, MCD_SAVER_FLASH_PROXY, MCD_SAVER_FLASH_PROXY, "",
                abi.encodeWithSignature('actionWithLoan(uint256,address,uint256,uint256,uint256,uint256,uint256,bool)',
                _cdpId, _joinAddr, _amount, loanAmount, _minPrice, _exchangeType, _gasCost, isRepay)
            );
        } else  {
            IDAI.flashBorrowToken(loanAmount, MCD_SAVER_FLASH_PROXY, MCD_SAVER_FLASH_PROXY, "",
                abi.encodeWithSignature('actionWithLoan(uint256,address,uint256,uint256,uint256,uint256,uint256,bool)',
                _cdpId, _joinAddr, _amount, loanAmount, _minPrice, _exchangeType, _gasCost, isRepay)
            );
        }

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_PROXY, 0);
    }
}

contract MCDSaverFlashProxy is MCDSaverProxy {

    IDaiToken public constant IDAI = IDaiToken(NEW_IDAI_ADDRESS);
    Manager public constant manager = Manager(MANAGER_ADDRESS);

    function actionWithLoan(
        uint _cdpId,
        address _joinAddr,
        uint _amount,
        uint _loanAmount,
        uint _minPrice,
        uint _exchangeType,
        uint _gasCost,
        bool isRepay
    ) public {

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

    function() external payable {}

}
