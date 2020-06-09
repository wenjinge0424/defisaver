const AaveBasicProxy = artifacts.require("./AaveBasicProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {
        await deployer.deploy(AaveBasicProxy, {gas: 3000000, overwrite: deployAgain});
    });
};

