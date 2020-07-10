const CompShifter = artifacts.require("./CompShifter.sol");
const McdShifter = artifacts.require("./McdShifter.sol");

const LoanShifterTaker = artifacts.require("./LoanShifterTaker.sol");
const LoanShifterReceiver = artifacts.require("./LoanShifterReceiver.sol");
require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    deployer.then(async () => {


        // STEP 1
        // await deployer.deploy(LoanShifterReceiver, {gas: 5000000, overwrite: deployAgain});

        // STEP 2 (Add LoanShifterReceiver address to the Taker contract)
        // await deployer.deploy(CompShifter, {gas: 5000000, overwrite: deployAgain});
        // await deployer.deploy(McdShifter, {gas: 5000000, overwrite: deployAgain});
        // const compShifterAddress = (await CompShifter.deployed()).address;
        // const mcdShifterAddress = (await McdShifter.deployed()).address;

        // await deployer.deploy(LoanShifterTaker, {gas: 5000000, overwrite: deployAgain});
        // const loanShifterTakerAddress = (await LoanShifterTaker.deployed()).address;

        // const taker = await LoanShifterTaker.at(loanShifterTakerAddress);
        // await taker.addProtocol(0, mcdShifterAddress);
        // await taker.addProtocol(1, compShifterAddress);

        // STEP 3 (Set LoanShiftReceiver address here)
        const receiver = await LoanShifterReceiver.at('0xD833215cBcc3f914bD1C9ece3EE7BF8B14f841bb');
        await receiver.setLoanShiftTaker('0x5b9b42d6e4B2e4Bf8d42Eba32D46918e10899B66'); // (Set LoanShiftTaker address here)
    });
};

