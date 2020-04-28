pragma solidity ^0.5.0;

import "../../flashloan/aave/FlashLoanReceiverBase.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/CTokenInterface.sol";

/// @title Receives FL from Aave and imports the position to DSProxy
contract CompoundImportFlashLoan is FlashLoanReceiverBase {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant COMPOUND_BASIC_PROXY = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
    }

    /// @notice Called by Aave when sending back the FL amount
    /// @param _reserve The address of the borrowed token
    /// @param _amount Amount of FL tokens received
    /// @param _fee FL Aave fee
    /// @param _params The params that are sent from the original FL caller contract
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external {

        (
            address cCollateralToken,
            address cBorrowToken,
            address user,
            address proxy
        )
        = abi.decode(_params, (address,address,address,address));

        // repay compound debt
        CTokenInterface(cBorrowToken).repayBorrowBehalf(user, _amount);

        // transfer cTokens to proxy
        uint cTokenBalance =  CTokenInterface(cCollateralToken).balanceOf(user);
        CTokenInterface(cCollateralToken).transferFrom(user, proxy, cTokenBalance);

        // borrow
        bytes memory proxyData = getProxyData(_reserve, cBorrowToken, (_amount + _fee));
        DSProxyInterface(proxy).execute(COMPOUND_BASIC_PROXY, proxyData);

        // Repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    /// @notice Formats function data call so we can call it through DSProxy
    /// @param _borrowToken Token address we will borrow
    /// @param _cBorrowToken CToken address we will borrow
    /// @param _amount Amount that will be borrowed
    /// @return proxyData Formated function call data
    function getProxyData(address _borrowToken, address _cBorrowToken, uint _amount) internal returns (bytes memory proxyData) {
        proxyData = abi.encodeWithSignature(
            "borrow(address,address,uint256,bool)",
            _borrowToken, _cBorrowToken, _amount, false);
    }
}
