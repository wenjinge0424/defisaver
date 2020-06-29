const CompoundSubscriptionsProxy = artifacts.require("./CompoundSubscriptionsProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {
        await deployer.deploy(CompoundSubscriptionsProxy, {gas: 700000, overwrite: deployAgain});
    });
};

