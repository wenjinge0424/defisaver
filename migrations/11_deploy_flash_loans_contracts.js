const MCDSaverFlashProxy = artifacts.require("./MCDSaverFlashProxy.sol");
const MCDFlashLoanTaker = artifacts.require("./MCDFlashLoanTaker.sol");
const FlashLoanLogger = artifacts.require("./FlashLoanLogger.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {
        // NOTICE: deploy seperatly and swith the addresses in the contracts

        // await deployer.deploy(FlashLoanLogger, {gas: 6000000, overwrite: deployAgain});
        // await deployer.deploy(MCDSaverFlashProxy, {gas: 6000000, overwrite: deployAgain});
        await deployer.deploy(MCDFlashLoanTaker, {gas: 6000000, overwrite: deployAgain});
    });
};
