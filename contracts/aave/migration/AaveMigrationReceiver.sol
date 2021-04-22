// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/SafeERC20.sol";
import "../../DS/DSProxy.sol";
import "../../auth/AdminAuth.sol";
import "./AaveMigration.sol";

contract AaveMigrationReceiver is AdminAuth {
    using SafeERC20 for ERC20;

    address public constant AAVE_MIGRATION_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant AAVE_V2_LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    function executeOperation(
        address[] calldata borrowAssets,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        address initiator,
        bytes calldata params
    ) public returns (bool) {
        (address market, address[] memory collTokens, uint256[] memory modes) =
            abi.decode(params, (address, address[], uint256[]));

        // send loan tokens to proxy
        for (uint256 i = 0; i < borrowAssets.length; i++) {
            ERC20(borrowAssets[i]).transfer(AAVE_MIGRATION_ADDR, amounts[i]);
        }

        AaveMigration.MigrateLoanData memory migrateLoanData =
            AaveMigration.MigrateLoanData({
                market: market,
                collAssets: collTokens,
                borrowAssets: borrowAssets,
                borrowAmounts: amounts,
                fees: fees,
                modes: modes
            });

        // call ds proxy
        DSProxy(payable(initiator)).execute{value: address(this).balance}(
            AAVE_MIGRATION_ADDR,
            abi.encodeWithSignature(
                "migrateLoan((address,address[],address[],uint256[],uint256[],uint256[]))",
                migrateLoanData
            )
        );

        returnFL(borrowAssets, amounts, fees);

        return true;
    }

    function returnFL(
        address[] memory _borrowAssets,
        uint256[] memory _amounts,
        uint256[] memory _fees
    ) internal {
        // return FL
        for (uint256 i = 0; i < _borrowAssets.length; i++) {
            ERC20(_borrowAssets[i]).safeApprove(AAVE_V2_LENDING_POOL, (_amounts[i] + _fees[i]));
        }
    }

    /// @dev allow contract to receive eth from sell
    receive() external payable {}
}
