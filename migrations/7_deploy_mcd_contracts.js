const MonitorMigrateProxy = artifacts.require("./MonitorMigrateProxy.sol");

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;
    // sub - 0x98711F45381F2Ac013eeE3037CBA2ba61C5C5Bcf
    // MonitorProxy - 0xCc53C650183Bb70E30F880FB045eF23217b9B54C

    // deployer.deploy(MCDSaverProxy, {gas: 6720000, overwrite: deployAgain});

    deployer.deploy(MonitorMigrateProxy, {gas: 6720000, overwrite: deployAgain});
};
