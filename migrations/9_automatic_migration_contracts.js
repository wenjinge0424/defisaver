const SubscriptionsProxy = artifacts.require("./SubscriptionsProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;
    const maxGas = 6720000;

   deployer.deploy(SubscriptionsProxy, {gas: maxGas, overwrite: deployAgain});

};
