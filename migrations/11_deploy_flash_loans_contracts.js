const MCDSaverFlashProxy = artifacts.require("./MCDSaverFlashProxy.sol");
const MCDFlashLoanTaker = artifacts.require("./MCDFlashLoanTaker.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {

        // await deployer.deploy(MCDSaverFlashProxy, {gas: 6000000, overwrite: deployAgain});
        await deployer.deploy(MCDFlashLoanTaker, {gas: 6000000, overwrite: deployAgain});
    });
};
