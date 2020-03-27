pragma solidity ^0.5.0;

import "../aave/FlashLoanReceiverBase.sol";
import "../../mcd/saver_proxy/MCDSaverProxy.sol";
import "../../compound/CompoundBasicProxy.sol";

contract LoanMover is FlashLoanReceiverBase, MCDSaverProxy, CompoundBasicProxy {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant cDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    address payable public owner;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
            owner = msg.sender;
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        (
            uint cdpId,
            address joinAddr,
            address cCollateralAddr,
            bytes32 ilk,
            uint8 functionType
        )
         = abi.decode(_params, (uint256,address,address,bytes32,uint8));

        if (functionType == 1) {
            compound2Mcd(cdpId, joinAddr, _amount, cCollateralAddr, ilk);
        } else {
            mcd2Compound(cdpId, joinAddr, _amount, cCollateralAddr, ilk);

        }

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    function compound2Mcd(
        uint _cdpId,
        address _joinAddr,
        uint _loanAmount,
        address _cCollateralAddr,
        bytes32 _ilk
    ) internal {
        // repay Compound debt
        payback(DAI_ADDRESS, cDAI_ADDRESS, _loanAmount);

        // CTokenInterface(_cTokenAddr).redeem(_amount);
        uint redeemAmount = 0; //TODO: figure out redeem amount

        // add money and withdraw debt
        addCollateral(_cdpId, _joinAddr, redeemAmount);

        drawDai(_cdpId, _ilk, _loanAmount);
    }

    function mcd2Compound(
        uint _cdpId,
        address _joinAddr,
        uint _loanAmount,
        address _cCollateralAddr,
        bytes32 _ilk
    ) internal {
        address owner = getOwner(manager, _cdpId);
        (uint collateral, ) = getCdpInfo(manager, _cdpId, _ilk);

        // repay dai debt cdp
        paybackDebt(_cdpId, _ilk, _loanAmount, owner);

        // withdraw collateral from cdp
        uint collDrawn = drawCollateral(_cdpId, _ilk, _joinAddr, collateral);

        // deposit in Compound
        deposit(getUnderlyingAddr(_cCollateralAddr), _cCollateralAddr, collDrawn, true);

        // borrow dai debt
        borrow(DAI_ADDRESS, cDAI_ADDRESS, _loanAmount, true); // TODO: will send to msg.sender
    }


    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

}
