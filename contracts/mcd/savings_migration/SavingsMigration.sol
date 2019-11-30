pragma solidity ^0.5.0;

import "../maker/ScdMcdMigration.sol";
import "../../interfaces/ITokenInterface.sol";
import "../../constants/ConstantAddresses.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../savings/dydx/DydxSavingsProtocol.sol";
import "../../savings/dydx/lib/Types.sol";

contract SavingsProxyInterface {
    enum SavingsProtocol { Compound, Dydx, Fulcrum, Dsr }

    function deposit(SavingsProtocol _protocol, uint _amount) public;
    function withdraw(SavingsProtocol _protocol, uint _amount) public;
}

contract SavingsMigration is ConstantAddresses {

    ITokenInterface public constant iDai = ITokenInterface(IDAI_ADDRESS);
    CTokenInterface public constant cDai = CTokenInterface(CDAI_ADDRESS);
    SavingsProxyInterface public constant oldSavingsProxy = SavingsProxyInterface(0x296420A79fE17B72Eb4749ca26d4E53602f4EDef);
    SavingsProxyInterface public constant newSavingsProxy = SavingsProxyInterface(address(0));

    ScdMcdMigration public constant migrationContract = ScdMcdMigration(SCD_MCD_MIGRATION);

    function migrateSavings() external {

        uint fulcrumBalance = iDai.assetBalanceOf(address(this));
        uint compoundBalance = cDai.balanceOfUnderlying(address(this));

        if (compoundBalance != 0) {
            oldSavingsProxy.withdraw(SavingsProxyInterface.SavingsProtocol.Compound, compoundBalance);
        }

        if (fulcrumBalance != 0) {
            oldSavingsProxy.withdraw(SavingsProxyInterface.SavingsProtocol.Fulcrum, fulcrumBalance);
        }

        uint sumOfSai = compoundBalance + fulcrumBalance;
        migrationContract.swapSaiToDai(sumOfSai);

        if (compoundBalance != 0) {
            newSavingsProxy.deposit(SavingsProxyInterface.SavingsProtocol.Compound, compoundBalance);
        }

        if (fulcrumBalance != 0) {
            newSavingsProxy.deposit(SavingsProxyInterface.SavingsProtocol.Fulcrum, fulcrumBalance);
        }
    }
}
