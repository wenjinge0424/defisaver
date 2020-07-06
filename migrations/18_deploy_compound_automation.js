const CompoundSubscriptionsProxy = artifacts.require("./CompoundSubscriptionsProxy.sol");
const CompoundSubscriptions = artifacts.require("./CompoundSubscriptions.sol");
const CompoundMonitor = artifacts.require("./CompoundMonitor.sol");
const CompoundMonitorProxy = artifacts.require("./CompoundMonitorProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    const compoundFlashLoanTakerAddress = '0x1c214eCB456D0D4403984E5593BE7992CF8B9eB8';
    const changePeriod = 0;

    deployer.then(async () => {

    	// -------------------- first deploy this -----------------------------
        // await deployer.deploy(CompoundMonitorProxy, changePeriod, {gas: 2000000, overwrite: deployAgain});
    	// await deployer.deploy(CompoundSubscriptions, {gas: 4000000, overwrite: deployAgain});


    	// ------------------- second part ----------------------
    	// check SubscriptionProxy.sol before running this!
    	// set these two addresses manually 
    	const compoundMonitorProxyAddress = '0xB1cF8DE8e791E4Ed1Bd86c03E2fc1f14389Cb10a'; //(await CompoundMonitorProxy.deployed()).address;
    	const subscriptionsAddress = '0x52015EFFD577E08f498a0CCc11905925D58D6207'; //(await CompoundSubscriptions.deployed()).address;

        await deployer.deploy(CompoundSubscriptionsProxy, {gas: 700000, overwrite: deployAgain});
        await deployer.deploy(CompoundMonitor, compoundMonitorProxyAddress, subscriptionsAddress, compoundFlashLoanTakerAddress, {gas: 4000000, overwrite: deployAgain});
    	const compoundMonitorAddress = (await CompoundMonitor.deployed()).address;

    	const compoundMonitorProxy = await CompoundMonitorProxy.at(compoundMonitorProxyAddress);
    	await compoundMonitorProxy.setMonitor(compoundMonitorAddress);

    	const monitor = await CompoundMonitor.at(compoundMonitorAddress);
    	await monitor.addCaller('0x6c259ea1fCa0D1883e3FFFdDeb8a0719E1D7265f');
    });
};

