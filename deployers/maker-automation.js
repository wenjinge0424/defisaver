// We require the Buidler Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const bre = require("@nomiclabs/buidler");
const { deployContract } = require("./utils/deployer");
const { start } = require('./utils/starter');

async function main() {
     await deployContract("MCDMonitorV2", '0x47d9f61bADEc4378842d809077A5e87B9c996898', '0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a', '0x91f92970A201F507734E61a7100C8fc2f2EAF495');
}

start(main);
