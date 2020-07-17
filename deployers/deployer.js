const bre = require("@nomiclabs/buidler");
const ethers = require("ethers");
const dotenv = require('dotenv').config();

const deploy = async (contractName, resendCount, nonce, ...args) => {

	try {
		const Contract = await bre.ethers.getContractFactory(contractName);
		const provider = await bre.ethers.provider;
		const defaultGasPrice = bre.network.config.gasPrice;
		let newGasPrice = defaultGasPrice > 0 ? defaultGasPrice : await provider.getGasPrice();

		if (resendCount > 0) {
			const gasPrice = await provider.getGasPrice();
			newGasPrice = gasPrice.add(gasPrice.mul(resendCount.toString()).div("10"));
		}

		const options = {gasPrice: ethers.BigNumber.from(newGasPrice.toString()), nonce: nonce};

		let contract;
		if (args.length == 1 && args[0].length == 0) {
			contract = await Contract.deploy(options);
		} else {
			contract = await Contract.deploy(...args, options);
		}

	  	const action = resendCount > 0 ? 'Resending' : 'Deploying';
	  	console.log(`${action} ${contractName}: ${contract.deployTransaction.hash} with gasPrice: ${newGasPrice.toString()}`);
	  	
	  	await contract.deployed();

	  	console.log(`${contractName} deployed to:`, contract.address);
	  	console.log('-------------------------------------------------------------');
	  	return contract;
	} catch (e) {
		console.log(e);
		return null;
	}	
}

const deployWithResend = (contractName, resendCount, nonce, ...args) => new Promise((resolve) => {
	let deployPromise = deploy(contractName, resendCount, nonce, args);
	const timeoutId = setTimeout(() => resolve(deployWithResend(contractName, resendCount+1, nonce, ...args)),  process.env.TIMEOUT_MINUTES * 60 * 1000);
	deployPromise.then((contract) => {
		clearTimeout(timeoutId);

		if (contract !== null) resolve(contract);

		return;
	})
})

const deployContract = async (contractName, ...args) => {
	const signers = await bre.ethers.getSigners();
	const address = await signers[0].getAddress();
	const nonce = await bre.ethers.provider.getTransactionCount(address);

	return deployWithResend(contractName, 0, nonce, ...args);
}

module.exports = {
	deploy,
	deployWithResend,
	deployContract
}