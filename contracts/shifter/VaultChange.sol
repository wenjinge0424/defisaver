pragma solidity ^0.6.0;

import "../DS/DSProxy.sol";
import "../mcd/maker/Manager.sol";
import "../mcd/maker/Join.sol";
import "../mcd/maker/DaiJoin.sol";
import "../mcd/saver_proxy/SaverProxyHelper.sol";
import "../mcd/flashloan/MCDOpenProxyActions.sol";
import "../utils/FlashLoanReceiverBase.sol";
import "../utils/ExchangeDataParser.sol";
import "../exchange/SaverExchangeCore.sol";
import "../interfaces/ERC20.sol";

contract VaultChange is FlashLoanReceiverBase, SaverProxyHelper, ExchangeDataParser, SaverExchangeCore {
    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant OPEN_PROXY_ACTIONS = 0x6d0984E80a86f26c0dd564ca0CF74a8E9Da03305;
    address public constant ETH_JOIN_ADDRESS = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant JUG_ADDRESS = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    DaiJoin public constant daiJoin = DaiJoin(DAI_JOIN_ADDRESS);
    Manager public constant manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

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
    external override {
        (
            uint cdpId,
            address joinAddrFrom,
            address joinAddrTo,
            address[3] memory exAddr,
            uint[5] memory exNum,
            bytes memory callData
        )
        = abi.decode(_params, (uint256,address,address,address[3],uint256[5],bytes));

        (uint256 collateral, ) = getCdpInfo(manager, cdpId, manager.ilks(cdpId));

        // payback whole dai debt
        paybackDebt(cdpId, manager.ilks(cdpId), _amount, address(uint160(getOwner(manager, cdpId))));

        // withdraw coll
        drawMaxCollateral(cdpId, joinAddrFrom, collateral);

        // sell coll
        (, uint buyAmount) = _sell(encodeExchangeData(exAddr, exNum, callData));

        // open new cdp deposit and withdraw
        openAndWithdraw(buyAmount, (_amount + _fee), cdpId, joinAddrTo);

        // repay FL
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function openAndWithdraw(uint _collAmount, uint _debtAmount, uint _cdpId, address _joinAddrTo) internal {

        address proxy = manager.owns(_cdpId);
        bytes32 ilk = Join(_joinAddrTo).ilk();

        if (_joinAddrTo == ETH_JOIN_ADDRESS) {
            MCDOpenProxyActions(OPEN_PROXY_ACTIONS).openLockETHAndDraw{value: address(this).balance}(
                address(manager),
                JUG_ADDRESS,
                ETH_JOIN_ADDRESS,
                DAI_JOIN_ADDRESS,
                ilk,
                _debtAmount,
                proxy
            );
        } else {
            ERC20(getCollateralAddr(_joinAddrTo)).approve(OPEN_PROXY_ACTIONS, uint256(-1));

            MCDOpenProxyActions(OPEN_PROXY_ACTIONS).openLockGemAndDraw(
                address(manager),
                JUG_ADDRESS,
                _joinAddrTo,
                DAI_JOIN_ADDRESS,
                ilk,
                _collAmount,
                _debtAmount,
                true,
                proxy
            );
        }
    }

    function drawMaxCollateral(uint _cdpId, address _joinAddr, uint _amount) internal returns (uint) {
        manager.frob(_cdpId, -toPositiveInt(_amount), 0);
        manager.flux(_cdpId, address(this), _amount);

        uint joinAmount = _amount;

        if (Join(_joinAddr).dec() != 18) {
            joinAmount = _amount / (10 ** (18 - Join(_joinAddr).dec()));
        }

        Join(_joinAddr).exit(address(this), joinAmount);

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            Join(_joinAddr).gem().withdraw(joinAmount); // Weth -> Eth
        }

        return joinAmount;
    }

    function paybackDebt(uint _cdpId, bytes32 _ilk, uint _daiAmount, address _owner) internal {
        address urn = manager.urns(_cdpId);

        uint wholeDebt = getAllDebt(VAT_ADDRESS, urn, urn, _ilk);

        if (_daiAmount > wholeDebt) {
            ERC20(DAI_ADDRESS).transfer(_owner, sub(_daiAmount, wholeDebt));
            _daiAmount = wholeDebt;
        }

        daiJoin.dai().approve(DAI_JOIN_ADDRESS, _daiAmount);
        daiJoin.join(urn, _daiAmount);

        manager.frob(_cdpId, 0, normalizePaybackAmount(VAT_ADDRESS, urn, _ilk));
    }

    // ADMIN ONLY FAIL SAFE FUNCTION IF FUNDS GET STUCK
    function withdrawStuckFunds(address _tokenAddr, uint _amount) public {
        require(msg.sender == owner, "Only owner");

        if (_tokenAddr == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            owner.transfer(_amount);
        } else {
            ERC20(_tokenAddr).transfer(owner, _amount);
        }
    }

    receive() external virtual override(FlashLoanReceiverBase, SaverExchangeCore) payable {}
}
