

const Web3 = require('web3');

require('dotenv').config();

const DSProxy = require('../../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../../build/contracts/ProxyRegistryInterface.json');
const CTokenInterface = require('../../build/contracts/CTokenInterface.json');
const CompoundLoanInfo = require('../../build/contracts/CompoundLoanInfo.json');
const CompoundMonitor = require('../../build/contracts/CompoundMonitor.json');
const CompoundSubscriptionsProxy = require('../../build/contracts/CompoundSubscriptionsProxy.json');

const proxyRegistryAddr = '0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4';
const compoundLoanInfoAddr = '0x9d16742a47490A47d3f85E06fcfD52aCA3E5A88d';
const subscriptionsProxyAddr = '0x43eaA91b4222fAA7222bcE76DCB123Fd6D280884';
const compoundMonitorAddr = '0xF3aD78068511E4cD6a2FF4bBbAB1585817098393';

const zeroAddr = '0x0000000000000000000000000000000000000000';
const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const CETH_ADDRESS = '0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5';

const DAI_ADDRESS = '0x6b175474e89094c44da98b954eedeac495271d0f';
const CDAI_ADDRESS = '0x5d3a536e4d6dbd6114cc1ead35777bab948e3643';

const MAX_UINT = '115792089237316195423570985008687907853269984665640564039457584007913129639935';

const tokenJoinAddrData = {
    '1': {
        'ETH': '0x2F0b23f53734252Bda2277357e97e1517d6B042A',
        'BAT': '0x3D0B1912B66114d4096F48A8CEe3A56C231772cA',
        'GNT': '0xc667ac878fd8eb4412dcad07988fea80008b65ee',
        'OMG': '0x2ebb31f1160c7027987a03482ab0fec130e98251',
        'ZRX': '0x1f4150647b4aa5eb36287d06d757a5247700c521',
        'REP': '0xd40163ea845abbe53a12564395e33fe108f90cd3',
        'DGD': '0xd5f63712af0d62597ad6bf8d357f163bc699e18c',
    },
    '42': {
        'ETH': '0x775787933e92b709f2a3c70aa87999696e74a9f8',
        'BAT': '0x2a4c485b1b8dfb46accfbecaf75b6188a59dbd0a',
        'GNT': '0xc667ac878fd8eb4412dcad07988fea80008b65ee',
        'OMG': '0x2ebb31f1160c7027987a03482ab0fec130e98251',
        'ZRX': '0x1f4150647b4aa5eb36287d06d757a5247700c521',
        'REP': '0xd40163ea845abbe53a12564395e33fe108f90cd3',
        'DGD': '0xd5f63712af0d62597ad6bf8d357f163bc699e18c',
    }
};

const getTokenJoinAddr = (type) => {
    return tokenJoinAddrData['1'][type];
}

const initContracts = async () => {
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.INFURA_ENDPOINT));

    account = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY)
    web3.eth.accounts.wallet.add(account)

    registry = new web3.eth.Contract(ProxyRegistryInterface.abi, proxyRegistryAddr);

    proxyAddr = await registry.methods.proxies(account.address).call();
    proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);

    cDai = new web3.eth.Contract(CTokenInterface.abi, CDAI_ADDRESS);
    cEth = new web3.eth.Contract(CTokenInterface.abi, CETH_ADDRESS);

    compoundLoanInfo = new web3.eth.Contract(CompoundLoanInfo.abi, compoundLoanInfoAddr);
    compoundMonitor = new web3.eth.Contract(CompoundMonitor.abi, compoundMonitorAddr);
};

function getAbiFunction(contract, functionName) {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}

(async () => {
    await initContracts();

    const ratio = await getRatio(proxyAddr);

    console.log(ratio);

    // await subscribe('3900000000000000000', '4300000000000000000', '4000000000000000000', '4000000000000000000', true);

    await repayFor('0.003', CETH_ADDRESS, CDAI_ADDRESS, proxyAddr);

})();

const getRatio = async (user) => {
    try {
        const ratio = await compoundLoanInfo.methods.getRatio(user).call();

        return ratio.toString();
    } catch(err) {
        console.log(err);
    }
};

// subscribe(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, bool _boostEnabled)
const subscribe = async (minRatio, maxRatio, optimalBoost, optimalRepay, boostEnabled) => {
    try {
        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundSubscriptionsProxy, 'subscribe'),
        [minRatio, maxRatio, optimalBoost, optimalRepay, boostEnabled]);

        const tx = await proxy.methods['execute(address,bytes)'](subscriptionsProxyAddr, data).send({
            from: account.address, gas: 400000, gasPrice: 7100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

// const unsubscribe = async (amount, cCollAddress, cBorrowAddress) => {
//     try {
//         amount = web3.utils.toWei(amount, 'ether');

//         const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundSaverProxy, 'boost'),
//         [[amount, 0, 3, 0, 0], [cCollAddress, cBorrowAddress, zeroAddr], "0x0"]);

//         const tx = await proxy.methods['execute(address,bytes)'](compoundSaverProxyAddr, data).send({
//             from: account.address, gas: 1300000, gasPrice: 5100000000});

//         console.log(tx);
//     } catch(err) {
//         console.log(err);
//     }
// };

const update = async (minRatio, maxRatio, optimalBoost, optimalRepay, boostEnabled) => {
    try {

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundSubscriptionsProxy, 'update'),
        [minRatio, maxRatio, optimalBoost, optimalRepay, boostEnabled]);

        const tx = await proxy.methods['execute(address,bytes)'](subscriptionsProxyAddr, data).send({
            from: account.address, gas: 300000, gasPrice: 8100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const boostFor = async (amount, cCollAddress, cBorrowAddress) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundSaverProxy, 'boost'),
        [[amount, 0, 3, 0, 0], [cCollAddress, cBorrowAddress, zeroAddr], "0x0"]);

        const tx = await proxy.methods['execute(address,bytes)'](compoundSaverProxyAddr, data).send({
            from: account.address, gas: 1300000, gasPrice: 5100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const repayFor = async (amount, cCollAddress, cBorrowAddress, userAddr) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const tx = await compoundMonitor.methods.repayFor(
            [amount, 0, 3, 0, 0], [cCollAddress, cBorrowAddress, zeroAddr], "0x0", userAddr).send({
                from: account.address, gas: 2300000, gasPrice: 7100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};








