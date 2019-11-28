pragma solidity ^0.5.0;

import "../maker/ScdMcdMigration.sol";

contract SavingsProxyInterface {
    enum SavingsProtocol { Compound, Dydx, Fulcrum, Dsr }

    function deposit(SavingsProtocol _protocol, uint _amount) public;
    function withdraw(SavingsProtocol _protocol, uint _amount) public;
}

contract SavingsMigration {

    SavingsProxyInterface public constant oldSavingsProxy = SavingsProxyInterface(address(0));
    SavingsProxyInterface public constant newSavingsProxy = SavingsProxyInterface(address(0));

    ScdMcdMigration public constant migrationContract = ScdMcdMigration(address(0));

    function migrateSavings(uint _compoundBalance, uint _dydxBalance, uint _fulcrumBalance) external {

        if (_compoundBalance != 0) {
            oldSavingsProxy.withdraw(SavingsProxyInterface.SavingsProtocol.Compound, _compoundBalance);
        }

        if (_dydxBalance != 0) {
            oldSavingsProxy.withdraw(SavingsProxyInterface.SavingsProtocol.Dydx, _dydxBalance);
        }

        if (_fulcrumBalance != 0) {
            oldSavingsProxy.withdraw(SavingsProxyInterface.SavingsProtocol.Fulcrum, _fulcrumBalance);
        }

        uint sumOfSai = _compoundBalance + _dydxBalance + _fulcrumBalance;
        migrationContract.swapSaiToDai(sumOfSai);

        if (_compoundBalance != 0) {
            newSavingsProxy.deposit(SavingsProxyInterface.SavingsProtocol.Compound, _compoundBalance);
        }

        if (_dydxBalance != 0) {
            newSavingsProxy.deposit(SavingsProxyInterface.SavingsProtocol.Dydx, _dydxBalance);
        }

        if (_fulcrumBalance != 0) {
            newSavingsProxy.deposit(SavingsProxyInterface.SavingsProtocol.Fulcrum, _fulcrumBalance);
        }
    }
}
