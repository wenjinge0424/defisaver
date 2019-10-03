const SavingsManager = artifacts.require("./SavingsManager.sol");
const sDai = artifacts.require("./sDai.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    // deployer.deploy(SavingsManager, {gas: 6720000, overwrite: deployAgain})
    // .then(() => {
    //     return deployer.deploy(sDai, SavingsManager.address, {gas: 6720000, overwrite: deployAgain});
    //  })
};
