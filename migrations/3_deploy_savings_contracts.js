const SavingsProxy = artifacts.require("./SavingsProxy.sol");
const DydxSavingsProtocol = artifacts.require("./DydxSavingsProtocol.sol");
const CompoundSavingsProtocol = artifacts.require("./CompoundSavingsProtocol.sol");
const AaveSavingsProtocol = artifacts.require("./AaveSavingsProtocol.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {

        // --------- first deploy this part ---------------------------------
        // await deployer.deploy(DydxSavingsProtocol, {gas: 6000000, overwrite: deployAgain})
        // await deployer.deploy(CompoundSavingsProtocol, {gas: 6000000, overwrite: deployAgain})
        // await deployer.deploy(AaveSavingsProtocol, {gas: 3000000, overwrite: deployAgain})

        // --------- change addresses in SavingsProxy contract and then deploy this part --------------

        await deployer.deploy(SavingsProxy, {gas: 3000000, overwrite: deployAgain})
        // let savingsProxy = await SavingsProxy.deployed()
    });
};
