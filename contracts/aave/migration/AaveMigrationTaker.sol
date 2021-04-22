// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../automatic/AaveSubscriptions.sol";

import "../../auth/ProxyPermission.sol";
import "../../interfaces/ILendingPool.sol";
import "../../interfaces/ILendingPoolV2.sol";
import "../../interfaces/ILendingPoolAddressesProvider.sol";

contract AaveMigrationTaker is ProxyPermission {
    uint16 public constant AAVE_REFERRAL_CODE = 64;

    address public constant AAVE_V1_LENDING_POOL_ADDRESSES = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;
    address public constant AAVE_V1_SUBSCRIPTION_ADDR = 0xe08ff7A2BADb634F0b581E675E6B3e583De086FC;

    address public constant AAVE_V1_MONITOR_PROXY = 0xfA560Dba3a8D0B197cA9505A2B98120DD89209AC;

    function migrateV1Position(
        address _market,
        address[] memory _collTokens,
        address[] memory _borrowTokens,
        uint256[] memory _flModes,
        address _aaveMigrationAddr
    ) public {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        address userProxy = address(this); // because it's called in the context of DSProxy

        (address[] memory assets, uint256[] memory amounts, uint256[] memory modes) =
            getUserBorrows(userProxy, _borrowTokens);

        bytes memory data = abi.encode(_market, _collTokens, modes);

        // give permission to receiver and execute tx
        givePermission(_aaveMigrationAddr);

        ILendingPoolV2(lendingPool).flashLoan(
            _aaveMigrationAddr,
            assets,
            amounts,
            _flModes,
            address(this),
            data,
            AAVE_REFERRAL_CODE
        );

        removePermission(_aaveMigrationAddr);

        unsubAutomationInNeeded(userProxy);
    }

    function unsubAutomationInNeeded(address _userProxy) internal {
        AaveSubscriptions aaveSub = AaveSubscriptions(AAVE_V1_SUBSCRIPTION_ADDR);

        if(aaveSub.isSubscribed(_userProxy)) {
            aaveSub.unsubscribe();

            removePermission(AAVE_V1_MONITOR_PROXY);
        }
    }

    function getUserBorrows(address _user, address[] memory _borrowTokens)
        public
        view
        returns (
            address[] memory borrowAddr,
            uint256[] memory borrowAmounts,
            uint256[] memory borrowRateModes
        )
    {
        address lendingPoolAddress =
            ILendingPoolAddressesProvider(AAVE_V1_LENDING_POOL_ADDRESSES).getLendingPool();

        borrowAddr = new address[](_borrowTokens.length);
        borrowAmounts = new uint256[](_borrowTokens.length);
        borrowRateModes = new uint256[](_borrowTokens.length);

        for (uint256 i = 0; i < _borrowTokens.length; i++) {
            address reserve = _borrowTokens[i];

            (, uint256 borrowBalance, , uint256 borrowRateMode, , , uint256 originationFee, , , ) =
                ILendingPool(lendingPoolAddress).getUserReserveData(reserve, _user);

            borrowAddr[i] = reserve;
            borrowAmounts[i] = borrowBalance + originationFee;
            borrowRateModes[i] = borrowRateMode;
        }
    }
}
