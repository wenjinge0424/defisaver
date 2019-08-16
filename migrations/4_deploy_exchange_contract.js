const SaverExchange = artifacts.require("./SaverExchange.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {
        // await deployer.deploy(SaverExchange, {gas: 6720000, overwrite: deployAgain});
    });
};
