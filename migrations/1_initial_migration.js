var Migrations = artifacts.require("./Migrations.sol");
const dotenv = require('dotenv').config();


module.exports = function(deployer, network) {
  if(network == 'kovan') {

    console.log(process.env.DEPLOY_AGAIN === 'true');
    if (process.env.DEPLOY_AGAIN === 'true') {
      deployer.deploy(Migrations);
    }
  } else if (network == 'rinkeby') {

  } else {
    deployer.deploy(Migrations);
  }
};
