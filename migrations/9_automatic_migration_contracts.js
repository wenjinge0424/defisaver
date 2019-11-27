const AutomaticMigrationProxy = artifacts.require("./AutomaticMigrationProxy.sol");
const AutomaticMigration = artifacts.require("./AutomaticMigration.sol");
const CustomMigrationProxyActions = artifacts.require("./CustomMigrationProxyActions.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;
    const maxGas = 6720000;

    // first this
   // deployer.deploy(CustomMigrationProxyActions, {gas: maxGas, overwrite: deployAgain});

    // then this, switch in AutomaticMigration the addr
    deployer.deploy(AutomaticMigrationProxy, {gas: maxGas, overwrite: deployAgain});
   deployer.deploy(AutomaticMigration, {gas: maxGas, overwrite: deployAgain});
};
