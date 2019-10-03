const SaverProxyMonitor = artifacts.require("./SaverProxyMonitor.sol");
const Monitor = artifacts.require("./Monitor.sol");
const MonitorProxy = artifacts.require("./MonitorProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    // deployer.deploy(SaverProxyMonitor, {gas: 6720000, overwrite: deployAgain})
    // .then(() => {
    //     return deployer.deploy(Monitor, SaverProxyMonitor.address, {gas: 6720000, overwrite: deployAgain});
    //  })
    //  .then(() => {
    //     return deployer.deploy(MonitorProxy, {gas: 6720000, overwrite: deployAgain});
    //  });
};
