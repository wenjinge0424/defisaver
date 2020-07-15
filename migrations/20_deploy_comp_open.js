const CompoundCreateTaker = artifacts.require("./CompoundCreateTaker.sol");
const CompoundCreateReceiver = artifacts.require("./CompoundCreateReceiver.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {
        await deployer.deploy(CompoundCreateTaker, {gas: 5000000, overwrite: deployAgain});
        await deployer.deploy(CompoundCreateReceiver, {gas: 5000000, overwrite: deployAgain});
    });
};

