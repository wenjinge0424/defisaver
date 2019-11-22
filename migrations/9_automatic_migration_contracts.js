const Subscriptions = artifacts.require("./Subscriptions.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;
    const maxGas = 6720000;

   deployer.deploy(Subscriptions, "0x322d58b9E75a6918f7e7849AEe0fF09369977e08", {gas: maxGas, overwrite: deployAgain});

};
