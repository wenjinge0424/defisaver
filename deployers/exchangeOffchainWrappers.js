// We require the Buidler Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const { deployContract } = require("./utils/deployer");
const { start } = require('./utils/starter');

async function main() {
 	const scp = await deployContract("ScpWrapper");
 	const zerox = await deployContract("ZeroxWrapper");

 	const SaverExchangeRegistry = await ethers.getContractFactory("SaverExchangeRegistry");
  	const registry = await SaverExchangeRegistry.attach('0x25dd3f51e0c3c3ff164ddc02a8e4d65bb9cbb12d');

 	console.log('setting scp');
 	await registry.addWrapper(scp.address);
 	console.log('setting zerox');
 	await registry.addWrapper(zerox.address);

 	console.log(`const scoWrapperAddr = '${scp.address}';`);
 	console.log(`const zeroxWrapperAddr = '${zerox.address}';`);
}

start(main);
