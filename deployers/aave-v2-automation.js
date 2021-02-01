// We require the Buidler Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const { deployContract } = require("./utils/deployer");
const { start } = require('./utils/starter');

async function main() {
 	// await deployContract("AaveMonitorProxyV2", 0);
 	// await deployContract("AaveSubscriptionsV2");


 	const monitorProxy = '0x380982902872836ceC629171DaeAF42EcC02226e';
 	const subscription = '0x6B25043BF08182d8e86056C6548847aF607cd7CD';
 	const saverProxy = '0x2de7c22e104ca305780995F991D980E818f33361';

 	// await deployContract("AaveSubscriptionsProxyV2");
 	await deployContract("AaveMonitorV2", monitorProxy, subscription, saverProxy);
}

start(main);
