const MCDMonitor = artifacts.require("./MCDMonitor.sol");
const MCDMonitorProxy = artifacts.require("./MCDMonitorProxy.sol");
const Subscriptions = artifacts.require("./Subscriptions.sol");
const SubscriptionsProxy = artifacts.require("./SubscriptionsProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;
    const maxGas = 6720000;

    deployer.then(async () => {
        let mcdSaverProxyAddress = '0x260c1543743fd03cd98a1d1edc3a4724af0a1fce';
        let botAddress = '0x5365a5bb25FF41C9D1E35c26259e0fa431d406be';

        // ------- first deploy this ----------
        // let changePeriod = 15; // set to 0 for Kovan deployment
        // await deployer.deploy(MCDMonitorProxy, changePeriod, {gas: maxGas, overwrite: deployAgain});


        // ------- deploy subscription, but change SubscriptionProxy.sol first ---------
        await deployer.deploy(SubscriptionsProxy, {gas: maxGas, overwrite: deployAgain});
        await deployer.deploy(Subscriptions, mcdSaverProxyAddress, {gas: maxGas, overwrite: deployAgain});

        let monitorProxy = await MCDMonitorProxy.deployed();
        let subscriptions = await Subscriptions.deployed();

        await deployer.deploy(MCDMonitor, monitorProxy.address, subscriptions.address, mcdSaverProxyAddress, {gas: maxGas, overwrite: deployAgain});
        let monitor = await MCDMonitor.deployed();
        await monitorProxy.setMonitor(monitor.address);
        await monitor.addCaller(botAddress);
    });
};
