// We require the Buidler Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const bre = require("@nomiclabs/buidler");
const { deployContract } = require("./utils/deployer");
const { start } = require('./utils/starter');

async function main() {
 	// const subscriptions = await deployContract("AaveSubscriptions");
 	// const monitorProxy = await deployContract("AaveMonitorProxy", 0);

 	await deployContract("AaveMonitor", '0xfA560Dba3a8D0B197cA9505A2B98120DD89209AC', '0xe08ff7A2BADb634F0b581E675E6B3e583De086FC', "0xCB127F47B716D4c257F5d5cc79A478215c608F0A")

 	// await deployContract("AaveSubscriptionsProxy");
}

start(main);
