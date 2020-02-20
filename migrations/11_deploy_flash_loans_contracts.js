const MCDSaverFlashProxy = artifacts.require("./MCDSaverFlashProxy.sol");
const MCDFlashLoanTaker = artifacts.require("./MCDFlashLoanTaker.sol");
// const FlashLoanLogger = artifacts.require("./FlashLoanLogger.sol");
// const MCDCloseFlashProxy = artifacts.require("./MCDCloseFlashProxy.sol");
// const MCDOpenFlashProxy = artifacts.require("./MCDOpenFlashProxy.sol");
// const MCDOpenProxyActions = artifacts.require("./MCDOpenProxyActions.sol");

// const FlashTokenDyDx = artifacts.require("./FlashTokenDyDx.sol");
// const TestLoan = artifacts.require("./TestLoan.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {
        // NOTICE: deploy seperatly and swith the addresses in the contracts

        // await deployer.deploy(MCDOpenProxyActions, {gas: 10000000, overwrite: deployAgain});

        // await deployer.deploy(FlashLoanLogger, {gas: 6000000, overwrite: deployAgain});
        await deployer.deploy(MCDSaverFlashProxy, {gas: 10000000, overwrite: deployAgain});

        // await deployer.deploy(MCDOpenFlashProxy, {gas: 10000000, overwrite: deployAgain});

        // await deployer.deploy(MCDCloseFlashProxy, {gas: 10000000, overwrite: deployAgain});
        // await deployer.deploy(MCDFlashLoanTaker, {gas: 6000000, overwrite: deployAgain});


        // Flash Token stuff

        // await deployer.deploy(FlashTokenDyDx, {gas: 6000000, overwrite: deployAgain});
        // await deployer.deploy(TestLoan, {gas: 6000000, overwrite: deployAgain});

    });
};
