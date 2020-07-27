// We require the Buidler Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const bre = require("@nomiclabs/buidler");
const { deployContract } = require("./utils/deployer");
const { start } = require('./utils/starter');

async function main() {
    const registry = await deployContract("SaverExchangeRegistry");
//  	const kyber = await deployContract("KyberWrapper");
//  	const oasis = await deployContract("OasisTradeWrapper");
//  	const uniswap = await deployContract("UniswapWrapper");

//  	const SaverExchangeRegistry = await ethers.getContractFactory("SaverExchangeRegistry");
//   	const registry = await SaverExchangeRegistry.attach('0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab');

//  	console.log('setting kyber');
//  	await registry.addWrapper(kyber.address);
//  	console.log('setting oasis');
//  	await registry.addWrapper(oasis.address);
//  	console.log('setting uniswap');
//  	await registry.addWrapper(uniswap.address);
}

start(main);
