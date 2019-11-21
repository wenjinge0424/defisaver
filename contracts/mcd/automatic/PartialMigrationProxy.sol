pragma solidity ^0.5.0;

import "../../DS/DSGuard.sol";
import "../../DS/DSProxy.sol";
import "../migration/PayProxyActions.sol";
import "../../Monitor.sol";
import "../../constants/ConstantAddresses.sol";
import "../maker/Manager.sol";
import "../../interfaces/ERC20.sol";
import "../../interfaces/TubInterface.sol";
import "../maker/ScdMcdMigration.sol";

/// @title Implements logic for migrating CDP to MCD cdp
contract PartialMigrationProxy is PayProxyActions, ConstantAddresses {

    enum MigrationType { WITH_MKR, WITH_CONVERSION, WITH_DEBT }

    function migratePart(bytes32 _cup, uint _ethAmount, uint _saiAmount, uint _minRatio, MigrationType _type, uint _currentVault) external {
        TubInterface tub = TubInterface(TUB_ADDRESS);
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
            pay(SCD_MCD_MIGRATION, _cup, _saiAmount);
        } else if (_type == MigrationType.WITH_CONVERSION) {
            payFeeWithGem(SCD_MCD_MIGRATION, _cup, _saiAmount, OTC_ADDRESS, MAKER_DAI_ADDRESS);
        } else if (_type == MigrationType.WITH_DEBT) {
            payFeeWithDebt(SCD_MCD_MIGRATION, _cup, _saiAmount, OTC_ADDRESS, _minRatio);
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
        DSGuard guard = getDSGuard();

        _tub.give(_cdpId, address(SCD_MCD_MIGRATION));
        uint newCdpId = ScdMcdMigration(SCD_MCD_MIGRATION).migrate(_cdpId);

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
