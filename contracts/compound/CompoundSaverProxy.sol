pragma solidity ^0.5.0;

import "../interfaces/CTokenInterface.sol";
import "./helpers/CEtherInterface.sol";
import "../mcd/saver_proxy/ExchangeHelper.sol";
import "../mcd/Discount.sol";
import "../DS/DSProxy.sol";
import "../loggers/CompoundLogger.sol";
import "./helpers/ComptrollerInterface.sol";

contract CompoundSaverProxy is ExchangeHelper {

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address public constant COMPOUND_LOGGER = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    /// @notice Withdraws collateral, converts to borrowed token and repays debt
    function repay(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));

        uint collAmount = _data[0]; // TODO: check max coll

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

        swapAmount -= getFee(swapAmount, user, borrowToken);

        repayDebt(swapAmount, _addrData[1], borrowToken, user);

        // handle 0x fee
        user.transfer(address(this).balance);

        CompoundLogger(COMPOUND_LOGGER).LogRepay(user, _data[0], swapAmount, collToken, borrowToken);
    }

    /// @notice Borrows more, converts to collateral, and adds to position
    function boost(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));
        uint borrowAmount = _data[0]; // TODO: check max

        require(CTokenInterface(_addrData[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        borrowAmount -= getFee(borrowAmount, user, borrowToken);

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

    function repayDebt(uint _amount, address _cBorrowToken, address _borrowToken, address _user) internal {
        // check borrow balance
        uint wholeDebt = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(_user);

        if (_amount > wholeDebt) {
            ERC20(_borrowToken).transfer(_user, (_amount - wholeDebt));
            _amount = wholeDebt;
        }

        approveCToken(_borrowToken, _cBorrowToken);

        if (_borrowToken == ETH_ADDRESS) {
            CEtherInterface(_cBorrowToken).repayBorrow.value(_amount)();
        } else {
            require(CTokenInterface(_cBorrowToken).repayBorrow(_amount) == 0);
        }
    }

    /// @notice Calculates the fee amount
    /// @param _amount Amount that is converted
    function getFee(uint _amount, address _user, address _tokenAddr) internal returns (uint feeAmount) {
        uint fee = SERVICE_FEE;

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(_user)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(_user);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        ERC20(_tokenAddr).transfer(WALLET_ID, feeAmount);
    }

    function enterMarket(address _cTokenAddrColl, address _cTokenAddrBorrow) internal {
        address[] memory markets = new address[](2);
        markets[0] = _cTokenAddrColl;
        markets[1] = _cTokenAddrBorrow;

        ComptrollerInterface(COMPTROLLER).enterMarkets(markets);
    }

    function approveCToken(address _tokenAddr, address _cTokenAddr) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).approve(_cTokenAddr, uint(-1));
        }
    }

    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

    function getUserAddress() internal returns (address) {
        DSProxy proxy = DSProxy(uint160(address(this)));

        return proxy.owner();
    }

}
