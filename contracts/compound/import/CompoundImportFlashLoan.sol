pragma solidity ^0.5.0;

import "../../flashloan/aave/FlashLoanReceiverBase.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/CTokenInterface.sol";

contract CompoundImportFlashLoan is FlashLoanReceiverBase {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant COMPOUND_BASIC_PROXY = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
    }

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

    function getProxyData(address _borrowToken, address _cBorrowToken, uint _amount) internal returns (bytes memory proxyData) {
        proxyData = abi.encodeWithSignature(
            "borrow(address,address,uint256,bool)",
            _borrowToken, _cBorrowToken, _amount, false);
    }
}
