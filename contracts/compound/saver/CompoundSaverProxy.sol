pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../exchange/SaverExchangeCore.sol";
import "../../loggers/DefisaverLogger.sol";
import "../helpers/CompoundSaverHelper.sol";

/// @title Contract that implements repay/boost functionality
contract CompoundSaverProxy is CompoundSaverHelper, SaverExchangeCore {

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Withdraws collateral, converts to borrowed token and repays debt
    /// @dev Called through the DSProxy
    /// @param _exData Exchange data
    /// @param _addrData Coll/Debt addresses [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    function repay(
        ExchangeData memory _exData,
        address[2] memory _addrData, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = payable(getUserAddress());

        uint maxColl = getMaxCollateral(_addrData[0], address(this));

        uint collAmount = (_exData.srcAmount > maxColl) ? maxColl : _exData.srcAmount;

        require(CTokenInterface(_addrData[0]).redeemUnderlying(collAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            (, swapAmount) = _sell(_exData);
            swapAmount -= getFee(swapAmount, user, _gasCost, _addrData[1]);
        } else {
            swapAmount = collAmount;
            swapAmount -= getGasCost(swapAmount, _gasCost, _addrData[1]);
        }

        paybackDebt(swapAmount, _addrData[1], borrowToken, user);

        // handle 0x fee
        user.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        logger.Log(address(this), msg.sender, "CompoundRepay", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

    /// @notice Borrows token, converts to collateral, and adds to position
    /// @dev Called through the DSProxy
    /// @param _exData Exchange data
    /// @param _addrData Coll/Debt addresses [cCollAddress, cBorrowAddress]
    /// @param _gasCost Gas cost for specific transaction
    function boost(
        ExchangeData memory _exData,
        address[2] memory _addrData, // cCollAddress, cBorrowAddress
        uint256 _gasCost
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = payable(getUserAddress());

        uint maxBorrow = getMaxBorrow(_addrData[1], address(this));
        uint borrowAmount = (_exData.srcAmount > maxBorrow) ? maxBorrow : _exData.srcAmount;

        require(CTokenInterface(_addrData[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        uint swapAmount = 0;

        if (collToken != borrowToken) {
            borrowAmount -= getFee(borrowAmount, user, _gasCost, _addrData[1]);

            _exData.srcAmount = borrowAmount;
            (,swapAmount) = _sell(_exData);
        } else {
            swapAmount = borrowAmount;
            swapAmount -= getGasCost(swapAmount, _gasCost, _addrData[1]);
        }

        approveCToken(collToken, _addrData[0]);

        if (collToken != ETH_ADDRESS) {
            require(CTokenInterface(_addrData[0]).mint(swapAmount) == 0);
        } else {
            CEtherInterface(_addrData[0]).mint{value: swapAmount}(); // reverts on fail
        }

        // handle 0x fee
        user.transfer(address(this).balance);

        // log amount, collToken, borrowToken
        logger.Log(address(this), msg.sender, "CompoundBoost", abi.encode(_exData.srcAmount, swapAmount, collToken, borrowToken));
    }

}
