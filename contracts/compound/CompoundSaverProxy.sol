pragma solidity ^0.5.0;

import "../mcd/saver_proxy/ExchangeHelper.sol";
import "../loggers/CompoundLogger.sol";
import "./CompoundSaverHelper.sol";

contract CompoundSaverProxy is CompoundSaverHelper, ExchangeHelper {

    /// @notice Withdraws collateral, converts to borrowed token and repays debt
    function repay(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));

        uint maxColl = getMaxCollateral(_addrData[0]);

        uint collAmount = (_data[0] > maxColl) ? maxColl : _data[0];

        require(CTokenInterface(_addrData[0]).redeemUnderlying(collAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        uint swapAmount = swap(
            [collAmount, _data[1], _data[2], _data[4]], // collAmount, minPrice, exchangeType, 0xPrice
            collToken,
            borrowToken,
            _addrData[2],
            _callData
        );

        swapAmount -= getFee(swapAmount, user, _data[3], _addrData[1]);

        paybackDebt(swapAmount, _addrData[1], borrowToken, user);

        // handle 0x fee
        user.transfer(address(this).balance);

        CompoundLogger(COMPOUND_LOGGER).LogRepay(user, _data[0], swapAmount, collToken, borrowToken);
    }

    /// @notice Borrows token, converts to collateral, and adds to position
    function boost(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));

        uint maxBorrow = getMaxBorrow(_addrData[1]);
        uint borrowAmount = (_data[0] > maxBorrow) ? maxBorrow : _data[0];

        require(CTokenInterface(_addrData[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        borrowAmount -= getFee(borrowAmount, user, _data[3], _addrData[1]);

        uint swapAmount = swap(
            [borrowAmount, _data[1], _data[2], _data[4]], // collAmount, minPrice, exchangeType, 0xPrice
            borrowToken,
            collToken,
            _addrData[2],
            _callData
        );

        approveCToken(collToken, _addrData[0]);

        if (collToken != ETH_ADDRESS) {
            require(CTokenInterface(_addrData[0]).mint(swapAmount) == 0);
        } else {
            CEtherInterface(_addrData[0]).mint.value(swapAmount)(); // reverts on fail
        }

        // handle 0x fee
        user.transfer(address(this).balance);

        CompoundLogger(COMPOUND_LOGGER).LogBoost(user, _data[0], swapAmount, collToken, borrowToken);

    }

}
