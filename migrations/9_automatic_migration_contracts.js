const AutomaticMigration = artifacts.require("./AutomaticMigration.sol");
const AutomaticMigrationProxy = artifacts.require("./AutomaticMigrationProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;
    const maxGas = 6720000;

   deployer.deploy(AutomaticMigrationProxy, {gas: maxGas, overwrite: deployAgain});
    deployer.deploy(AutomaticMigration, {gas: maxGas, overwrite: deployAgain});

};
