const DSAuthorityUnsubscribe = artifacts.require("./DSAuthorityUnsubscribe.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {
        await deployer.deploy(DSAuthorityUnsubscribe, {gas: 6700000, overwrite: deployAgain});
    });
};

