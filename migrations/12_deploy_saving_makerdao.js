const BidProxy = artifacts.require("./BidProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {

        await deployer.deploy(BidProxy, {gas: 2000000, overwrite: deployAgain});

    });
};
