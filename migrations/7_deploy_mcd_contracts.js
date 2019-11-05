const MCDSaverProxy = artifacts.require("./MCDSaverProxy.sol");

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.deploy(MCDSaverProxy, {gas: 6720000, overwrite: deployAgain})
};
