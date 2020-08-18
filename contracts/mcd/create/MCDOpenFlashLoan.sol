pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../exchange/SaverExchangeCore.sol";
import "./MCDOpenProxyActions.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/Manager.sol";
import "../../interfaces/Join.sol";

contract MCDOpenFlashLoan is SaverExchangeCore, AdminAuth, FlashLoanReceiverBase {
    address public constant OPEN_PROXY_ACTIONS = 0x6d0984E80a86f26c0dd564ca0CF74a8E9Da03305;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant ETH_JOIN_ADDRESS = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant JUG_ADDRESS = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        (
            uint[6] memory numData,
            address[5] memory addrData,
            bytes memory callData,
            address proxy
        )
         = abi.decode(_params, (uint256[6],address[5],bytes,address));

        ExchangeData memory exchangeData = ExchangeData({
            srcAddr: addrData[0],
            destAddr: addrData[1],
            srcAmount: numData[2],
            destAmount: numData[3],
            minPrice: numData[4],
            wrapper: addrData[3],
            exchangeAddr: addrData[2],
            callData: callData,
            price0x: numData[5]
        });

        openAndLeverage(numData[0], numData[1], addrData[4], proxy, _fee, exchangeData);

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function openAndLeverage(
        uint _collAmount,
        uint _daiAmount,
        address _joinAddr,
        address _proxy,
        uint _fee,
        ExchangeData memory _exchangeData
    ) public {

        (, uint256 collSwaped) = _sell(_exchangeData);

        bytes32 ilk = Join(_joinAddr).ilk();

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            MCDOpenProxyActions(OPEN_PROXY_ACTIONS).openLockETHAndDraw{value: address(this).balance}(
                MANAGER_ADDRESS,
                JUG_ADDRESS,
                ETH_JOIN_ADDRESS,
                DAI_JOIN_ADDRESS,
                ilk,
                (_daiAmount + _fee),
                _proxy
            );
        } else {
            Join(_joinAddr).gem().approve(OPEN_PROXY_ACTIONS, uint256(-1));

            MCDOpenProxyActions(OPEN_PROXY_ACTIONS).openLockGemAndDraw(
                MANAGER_ADDRESS,
                JUG_ADDRESS,
                _joinAddr,
                DAI_JOIN_ADDRESS,
                ilk,
                (_collAmount + collSwaped),
                (_daiAmount + _fee),
                true,
                _proxy
            );
        }
    }

    receive() external override(FlashLoanReceiverBase, SaverExchangeCore) payable {}
}
