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
        const receiver = await LoanShifterReceiver.at('0xA94B7f0465E98609391C623d0560C5720a3f2D33');
        await receiver.setLoanShiftTaker('0xFC628dd79137395F3C9744e33b1c5DE554D94882'); // (Set LoanShiftTaker address here)
    });
};

