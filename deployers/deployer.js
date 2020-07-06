const dotenv = require('dotenv').config();

const deploy = async (contractName, resendCount, nonce, ...args) => {

	try {
		const Contract = await ethers.getContractFactory(contractName);
		const provider = await ethers.getDefaultProvider('kovan');
		let newGasPrice = await provider.getGasPrice();

		if (resendCount > 0) {
			const gasPrice = await provider.getGasPrice();
			newGasPrice = gasPrice.add(gasPrice.mul(resendCount.toString()).div("10"));

			console.log('New gas price:', newGasPrice.toString());
		}

		const options = {gasPrice: ethers.BigNumber.from(newGasPrice.toString()), nonce: nonce};
		
		let contract;
		console.log("nonce", nonce);
		if (args.length == 1 && args[0].length == 0) {
			contract = await Contract.deploy(options);
		} else {
			contract = await Contract.deploy(...args, options);
		}

	  	const action = resendCount > 0 ? 'Resending' : 'Deploying';
	  	console.log(`${action} ${contractName}: `, contract.deployTransaction.hash);
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
	const timeoutId = setTimeout(() => resolve(deployWithResend(contractName, resendCount+1, nonce, ...args)),  1 * 3 * 1000);
	deployPromise.then((contract) => {
		clearTimeout(timeoutId);
		return contract;
	})
})

const deployContract = async (contractName, ...args) => {
	const address = '0x6c259ea1fCa0D1883e3FFFdDeb8a0719E1D7265f'; //process.env.OWNER_ADDRESS;
	const provider = await ethers.getDefaultProvider('kovan');
	const nonce = await provider.getTransactionCount(address);

	return deployWithResend(contractName, 0, nonce+1, ...args);
}

module.exports = {
	deploy,
	deployWithResend,
	deployContract
}