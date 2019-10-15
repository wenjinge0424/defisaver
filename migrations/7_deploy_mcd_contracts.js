const MCDSaverProxy = artifacts.require("./MCDSaverProxy.sol");
const OasisTrade = artifacts.require("./OasisTrade.sol");

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.deploy(OasisTrade, {gas: 6720000, overwrite: deployAgain})
};
