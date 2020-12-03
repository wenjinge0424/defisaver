// We require the Buidler Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const { deployContract } = require("./utils/deployer");
const { start } = require('./utils/starter');

async function main() {
 	await deployContract("AaveLoanInfoV2");
 	// await deployContract("AaveBasicProxyV2");

 	// need AaveBasicProxyV2
 	// await deployContract("AaveImportV2"); // needs funds to be sent for dydx flashloans
 	// await deployContract("AaveSaverProxyV2");

 	// need AaveImportV2 and AaveSaverProxyV2
 	// await deployContract("AaveSaverReceiverV2"); // needs funds to be sent for dydx flashloans
 	// await deployContract("AaveImportTakerV2");

 	// need AaveSaverReceiverV2
 	// await deployContract("AaveSaverTakerV2");

 	// send funds to AaveImportV2 and AaveSaverReveiverV2
}

start(main);
