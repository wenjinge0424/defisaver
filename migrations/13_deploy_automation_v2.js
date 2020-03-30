const AutomaticProxyV2 = artifacts.require("./AutomaticProxyV2.sol");
const MCDMonitorProxyV2 = artifacts.require("./MCDMonitorProxyV2.sol");
const MCDMonitorV2 = artifacts.require("./MCDMonitorV2.sol");
const SubscriptionsV2 = artifacts.require("./SubscriptionsV2.sol");
const SubscriptionsProxyV2 = artifacts.require("./SubscriptionsProxyV2.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {

    	// FIRST STEP
    	// 1. comment second step
    	// 2. deploy first step if needed
    	// ------------------------------------------------------------------------------------------------------
        
        // await deployer.deploy(MCDMonitorProxyV2, 0, {gas: 5000000, overwrite: deployAgain});

        // ------------------------------------------------------------------------------------------------------

        
        // don't comment this, change to specific address if needed
        let monitorProxyAddress = (await MCDMonitorProxyV2.deployed()).address;


        // SECOND STEP
        // 1. change MonitorProxyAddress in SubscriptionProxyV2
        // 2. comment first step
        // 3. uncomment second step
        // 2. deploy these
        // ------------------------------------------------------------------------------------------------------

        await deployer.deploy(AutomaticProxyV2, {gas: 5000000, overwrite: deployAgain});
        let automaticProxyAddress = (await AutomaticProxyV2.deployed()).address;
        
        await deployer.deploy(SubscriptionsV2, automaticProxyAddress, {gas: 5000000, overwrite: deployAgain});
        let subscriptionsAddress = (await SubscriptionsV2.deployed()).address;

        await deployer.deploy(SubscriptionsProxyV2, {gas: 5000000, overwrite: deployAgain});
        let subscriptionsProxyAddress = (await SubscriptionsProxyV2.deployed()).address;

        await deployer.deploy(MCDMonitorV2, monitorProxyAddress, subscriptionsAddress, automaticProxyAddress, {gas: 5000000, overwrite: deployAgain});
        let monitorAddress = (await MCDMonitorV2.deployed()).address;

        let monitorProxyV2 = await MCDMonitorProxyV2.deployed();
        await monitorProxyV2.setMonitor(monitorAddress);

        console.log({automaticProxyAddress});
        console.log({subscriptionsAddress});
        console.log({subscriptionsProxyAddress});
        console.log({monitorAddress});

        // ------------------------------------------------------------------------------------------------------
        
        
        // always log monitorProxyAddress at the end
        console.log({monitorProxyAddress});

        // to verify all contracts
        // truffle run verify MCDMonitorProxyV2 AutomaticProxyV2 MCDMonitorV2 SubscriptionsV2 SubscriptionsProxyV2 --network mainnet
    });
};

