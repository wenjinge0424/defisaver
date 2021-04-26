// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../automatic/AaveSubscriptions.sol";
import "../../aaveV2/automatic/AaveSubscriptionsV2.sol";

import "../../auth/ProxyPermission.sol";
import "../../interfaces/ILendingPool.sol";
import "../../interfaces/ILendingPoolV2.sol";
import "../../interfaces/ILendingPoolAddressesProvider.sol";
import "../../loggers/DefisaverLogger.sol";

/// @title Entry point for an AAVE v1 -> v2 position migration
contract AaveMigrationTaker is ProxyPermission {
    uint16 public constant AAVE_REFERRAL_CODE = 64;

    address public constant AAVE_V1_LENDING_POOL_ADDRESSES =
        0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;
    address public constant AAVE_V1_SUBSCRIPTION_ADDR = 0xe08ff7A2BADb634F0b581E675E6B3e583De086FC;
    address public constant AAVE_V2_SUBSCRIPTION_ADDR = 0x6B25043BF08182d8e86056C6548847aF607cd7CD;

    address public constant AAVE_V1_MONITOR_PROXY = 0xfA560Dba3a8D0B197cA9505A2B98120DD89209AC;
    address public constant AAVE_V2_MONITOR_PROXY = 0x380982902872836ceC629171DaeAF42EcC02226e;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    DefisaverLogger public logger = DefisaverLogger(DEFISAVER_LOGGER);

    struct FlMigrationData {
        address market;
        address[] collTokens;
        uint256[] modes;
        bool[] isColl;
    }

    /// @notice Call through DSProxy to migrate the position on the proxy
    /// @param _market Market address of Aave V2
    /// @param _collTokens Underlying supply addresses where user has non 0 balance
    /// @param _isColl Bool array indicating if the collTokens are set as collateral
    /// @param _borrowTokens Underlying borrow addresses where user has non 0 debt
    /// @param _flModes Type of aave V2 loan (array of 0 same size as borrowTokens)
    /// @param _aaveMigrationReceiverAddr Receiver address for aave fl
    function migrateV1Position(
        address _market,
        address[] memory _collTokens,
        bool[] memory _isColl,
        address[] memory _borrowTokens,
        uint256[] memory _flModes,
        address _aaveMigrationReceiverAddr
    ) public {
        address lendingPool = ILendingPoolAddressesProviderV2(_market).getLendingPool();
        address userProxy = address(this); // called by DSProxy, so it can be set like this

        (address[] memory assets, uint256[] memory amounts, uint256[] memory modes) =
            getUserBorrows(userProxy, _borrowTokens);

        FlMigrationData memory flData =
            FlMigrationData({
                market: _market,
                collTokens: _collTokens,
                modes: modes,
                isColl: _isColl
            });

        bytes memory data = abi.encode(flData);

        // give permission to receiver and execute tx
        givePermission(_aaveMigrationReceiverAddr);

        ILendingPoolV2(lendingPool).flashLoan(
            _aaveMigrationReceiverAddr,
            assets,
            amounts,
            _flModes,
            address(this),
            data,
            AAVE_REFERRAL_CODE
        );

        removePermission(_aaveMigrationReceiverAddr);

        unsubAutomationInNeeded(userProxy);

        logger.Log(
            address(this),
            msg.sender,
            "AaveMigration",
            abi.encode(_collTokens, _borrowTokens)
        );
    }

    function unsubAutomationInNeeded(address _userProxy) internal {
        AaveSubscriptions aaveSubV1 = AaveSubscriptions(AAVE_V1_SUBSCRIPTION_ADDR);
        AaveSubscriptionsV2 aaveSubV2 = AaveSubscriptionsV2(AAVE_V2_SUBSCRIPTION_ADDR);

        if (aaveSubV1.isSubscribed(_userProxy)) {
            AaveSubscriptions.AaveHolder memory holder = aaveSubV1.getHolder(_userProxy);

            // unsub and remove old permission
            aaveSubV1.unsubscribe();
            removePermission(AAVE_V1_MONITOR_PROXY);

            // sub and add permission
            givePermission(AAVE_V2_MONITOR_PROXY);
            aaveSubV2.subscribe(
                holder.minRatio,
                holder.maxRatio,
                holder.optimalRatioBoost,
                holder.optimalRatioRepay,
                holder.boostEnabled
            );
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
