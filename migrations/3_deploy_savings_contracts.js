const SavingsProxy = artifacts.require("./SavingsProxy.sol");
const DydxSavingsProtocol = artifacts.require("./DydxSavingsProtocol.sol");
const CompoundSavingsProtocol = artifacts.require("./CompoundSavingsProtocol.sol");
const FulcrumSavingsProtocol = artifacts.require("./FulcrumSavingsProtocol.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {
        await deployer.deploy(DydxSavingsProtocol, {gas: 6000000, overwrite: deployAgain})
        let dydxSavingsProtocol = await DydxSavingsProtocol.deployed()

        await deployer.deploy(CompoundSavingsProtocol, {gas: 6000000, overwrite: deployAgain})
        let compoundSavingsProtocol = await CompoundSavingsProtocol.deployed()

        await deployer.deploy(FulcrumSavingsProtocol, {gas: 6000000, overwrite: deployAgain})
        let fulcrumSavingsProtocol = await FulcrumSavingsProtocol.deployed()

        await deployer.deploy(SavingsProxy, compoundSavingsProtocol.address, dydxSavingsProtocol.address, fulcrumSavingsProtocol.address, {gas: 6000000, overwrite: deployAgain})
    });
};
