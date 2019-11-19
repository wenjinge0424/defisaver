const PartialMigration = artifacts.require("./PartialMigrationProxy.sol");
const MonitorMigrate = artifacts.require("./MonitorMigrateProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;
    const maxGas = 6720000;

    deployer.then(async () => {
        // before deploying first add SUBSCRIPTION and MONITOR address in Constant Addresses

       //  await deployer.deploy(PartialMigration, {gas: maxGas, overwrite: deployAgain});
        await deployer.deploy(MonitorMigrate, {gas: maxGas, overwrite: deployAgain});
    });
};
