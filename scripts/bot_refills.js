const Web3 = require('web3');

require('dotenv').config();

const Slack = require('node-slack');
const slack = new Slack('https://hooks.slack.com/services/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',{});

const contractAddr = '0xAc79b9E2A0Fc3DeD1fbf2Baf5F4AdA0d5a6E74cD';
const contractAbi = [{"constant":false,"inputs":[{"internalType":"uint256","name":"_daiAmount","type":"uint256"},{"internalType":"address","name":"_botAddress","type":"address"}],"name":"refill","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_bot","type":"address"},{"internalType":"bool","name":"_state","type":"bool"}],"name":"setBot","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"_newMinEth","type":"uint256"}],"name":"setMinEth","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_minEth","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"approvedBots","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"DAI_ADDRESS","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"minEth","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"UNISWAP_FACTORY","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"}];

const botsAddresses = [
    '0xb35ADA58F44eA477De41f3394cDcBf43857467F1',
    '0xFfC6cbEBd16297650e1e19B7117c5f0e5F82ca9f'
];

const callRefill = async (senderAcc, refilContract, amount, botAddr) => {
    const gasPrice = 20000000000; // await calculateGasPrice(); // 21 gwei
    const gasCost = 200000; // 3 mil

    console.log('Calling refil for: ', botAddr);

    slack.send({
        text: `:see_no_evil: Reffil for ${botAddr} :see_no_evil: `,
        channel: '#money-flow',
        username: 'Bot'
    });

    try {
        const res = await refilContract.methods.refill(amount, botAddr).send(
            { from: senderAcc, gas: gasCost, gasPrice }
        );
    } catch(err) {
        console.log(err);
    }
};


const DAI_AMOUNT = '250';

const refillBot = async () => {
    // Load account
    const web3 = new Web3(new Web3.providers.HttpProvider(process.env.INFURA_ENDPOINT));

    console.log(process.env.PRIV_KEY);

    const account = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY)
    web3.eth.accounts.wallet.add(account)

    const refilContract = new web3.eth.Contract(contractAbi, contractAddr);

    const minEth = await refilContract.methods.minEth().call();

    console.log('Min eth bot has to have: ', minEth/1e18);

    const daiAmount = web3.utils.toWei(DAI_AMOUNT, 'ether');;

    // Check blances
    for (let i = 0; i < botsAddresses.length; ++i) {
        let balance = await web3.eth.getBalance(botsAddresses[i]);

        console.log("Balance: ", balance, account.address);

        if (balance < minEth) {
           await callRefill(account.address, refilContract, daiAmount, botsAddresses[i]);
        }

    }

};

// (async () => {
//     await refillBot();
// })();

setInterval(refillBot, 60*5*1000);
