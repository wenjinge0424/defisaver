pragma solidity ^0.5.0;

import "../../DS/DSGuard.sol";
import "../migration/PayProxyActions.sol";
import "./Subscriptions.sol";
import "../../Monitor.sol";
import "../../constants/ConstantAddresses.sol";
import "../maker/Manager.sol";
import "../../interfaces/SaiProxyInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/TubInterface.sol";
import "../maker/ScdMcdMigration.sol";

/// @title Implements logic for migrating CDP to MCD cdp
contract PartialMigrationProxy is PayProxyActions, ConstantAddresses {

    address payable public constant scdMcdMigration = 0x97cB5A9aBcdBE291D0CD85915fA5b08746Fe948A;
    address public constant subscriptionsContract = 0x267a8E54a6510784A168A2B4cc177e34D4f670B8;
    address public constant monitorContract = 0x32ED63E1FD1D6D3E03A174088f6E1a32daD964FC;

    enum MigrationType { WITH_MKR, WITH_CONVERSION, WITH_DEBT }

    constructor() public {}

    function migratePart(bytes32 _cup, uint _ethAmount, uint _saiAmount, uint _minRatio, MigrationType _type, uint _currentVault) external {
        TubInterface tub = TubInterface(TUB_ADDRESS);
        SaiProxyInterface saiProxy = SaiProxyInterface(SAI_SAVER_PROXY);
        Manager manager = Manager(MANAGER_ADDRESS);

        // withdraw ETH
        uint ink = rdiv(_ethAmount, tub.per());
        tub.free(_cup, ink);

        tub.exit(ink);
        tub.gem().withdraw(_ethAmount);

        // create new cup
        bytes32 newCup = tub.open();
        lock(tub, newCup, _ethAmount);
        draw(tub, newCup, _saiAmount);

        // wipe old cup with SAI
        if (_type == MigrationType.WITH_MKR) {
            pay(scdMcdMigration, _cup, _saiAmount);
        } else if (_type == MigrationType.WITH_CONVERSION) {
            payFeeWithGem(scdMcdMigration, _cup, _saiAmount, OTC_ADDRESS, MAKER_DAI_ADDRESS);
        } else if (_type == MigrationType.WITH_DEBT) {
            payFeeWithDebt(scdMcdMigration, _cup, _saiAmount, OTC_ADDRESS, _minRatio);
        }

        tub.wipe(_cup, _saiAmount);

        // migrate new cup
        uint vaultId = migrate(newCup, tub);

        if (_currentVault > 0) {
            manager.shift(vaultId, _currentVault);
            // send old vault to WALLET_ID
            manager.give(vaultId, WALLET_ID);
        }
    }

        /// @dev Called by DSProxy
    function migrate(bytes32 _cdpId, TubInterface _tub) private returns(uint) {
        Subscriptions sub = Subscriptions(subscriptionsContract);
        Monitor monitor = Monitor(monitorContract);
        DSGuard guard = getDSGuard();

        _tub.give(_cdpId, address(scdMcdMigration));
        uint newCdpId = ScdMcdMigration(scdMcdMigration).migrate(_cdpId);

        // Authorize
        guard.forbid(address(monitor), address(this), bytes4(keccak256("execute(address,bytes)")));

        return newCdpId;
    }

    function draw(TubInterface tub, bytes32 cup, uint wad) private {
        if (wad > 0) {
            tub.draw(cup, wad);
        }
    }

    function lock(TubInterface tub, bytes32 cup, uint value) private {
        if (value > 0) {

            tub.gem().deposit.value(value)();

            uint ink = rdiv(value, tub.per());
            if (tub.gem().allowance(address(this), address(tub)) != uint(-1)) {
                tub.gem().approve(address(tub), uint(-1));
            }
            tub.join(ink);

            if (tub.skr().allowance(address(this), address(tub)) != uint(-1)) {
                tub.skr().approve(address(tub), uint(-1));
            }
            tub.lock(cup, ink);
        }
    }

    function getDSGuard() internal view returns (DSGuard) {
        DSProxy proxy = DSProxy(address(uint160(address(this))));
        DSAuth auth = DSAuth(address(proxy.authority));

        return DSGuard(address(auth));
    }
}
