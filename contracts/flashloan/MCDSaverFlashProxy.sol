pragma solidity ^0.5.0;

import "../mcd/saver_proxy/MCDSaverProxy.sol";


contract ManagerLike {
    function ilks(uint256) public view returns (bytes32);
}


contract MCDSaverFlashProxy is MCDSaverProxy {
    Manager public constant MANAGER = Manager(MANAGER_ADDRESS);

    function actionWithLoan(
        uint256[6] memory _data,
        uint256 _loanAmount,
        address _joinAddr,
        address _exchangeAddress,
        bytes memory _callData,
        bool isRepay
    ) public {
        // payback the CDP debt with loan amount
        address owner = getOwner(MANAGER, _data[0]);
        paybackDebt(_data[0], MANAGER.ilks(_data[0]), _loanAmount, owner);

        if (isRepay) {
            repay(_data, _joinAddr, _exchangeAddress, _callData);
        } else {
            boost(_data, _joinAddr, _exchangeAddress, _callData);
        }

        // repay the flash loan
        uint256 daiDrawn = drawDai(_data[0], MANAGER.ilks(_data[0]), _loanAmount);

        require(daiDrawn >= _loanAmount, "Loan debt to big for CDP");

        ERC20(DAI_ADDRESS).transfer(address(NEW_IDAI_ADDRESS), _loanAmount);
    }

    function() external payable {}
}
