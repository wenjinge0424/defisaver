const MCDSaverFlashProxy = artifacts.require("./MCDSaverFlashProxy.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {

        await deployer.deploy(MCDSaverFlashProxy, {gas: 6000000, overwrite: deployAgain});
    });
};
