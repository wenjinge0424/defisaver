const MonitorMigrate = artifacts.require("./MonitorMigrate.sol");

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.deploy(MonitorMigrate, {gas: 6720000, overwrite: deployAgain})
};
