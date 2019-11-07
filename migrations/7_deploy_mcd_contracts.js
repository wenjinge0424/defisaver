const MCDSaverProxy = artifacts.require("./MCDSaverProxy.sol");

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;
    // sub - 0x96f2F380B310a2aeE1850600139C3D6e7f304180
    // MonitorProxy - 0x69B5eeA9F5ff86f9C2988A525Da45dd89b3237ad

    deployer.deploy(MCDSaverProxy, {gas: 6720000, overwrite: deployAgain});
};
