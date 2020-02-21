

const Web3 = require('web3');

require('dotenv').config();

const DSProxy = require('../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../build/contracts/ProxyRegistryInterface.json');
const DSSProxyActions = require('../build/contracts/DSSProxyActions.json');
const MCDFlashLoanTaker = require('../build/contracts/MCDFlashLoanTaker.json');
const TestLoan = require('../build/contracts/TestLoan.json');

const proxyRegistryAddr = '0x64a436ae831c1672ae81f674cab8b6775df3475c';
const mcdFlashLoanTakerAddr = '0x13D67957E8D75502cd7c143F70eb659F5200F5c6';
const testLoanAddr = '0xc50f13fEf45EfA33B70483FF16381B9E4003b80C';

const ETH_ILK = '0x4554482d41000000000000000000000000000000000000000000000000000000';
const BAT_ILK = '0x4241542d41000000000000000000000000000000000000000000000000000000';

const zeroAddr = '0x0000000000000000000000000000000000000000';

const tokenJoinAddrData = {
    '1': {
        'ETH': '0x775787933e92b709f2a3c70aa87999696e74a9f8',
        'BAT': '0x2a4c485b1b8dfb46accfbecaf75b6188a59dbd0a',
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
    return tokenJoinAddrData['42'][type];
};

const initContracts = async () => {
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.KOVAN_INFURA_ENDPOINT));

    account = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY)
    web3.eth.accounts.wallet.add(account)

    registry = new web3.eth.Contract(ProxyRegistryInterface.abi, proxyRegistryAddr);

    proxyAddr = await registry.methods.proxies(account.address).call();
    proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);

    mcdFlashLoanTaker = new web3.eth.Contract(MCDFlashLoanTaker.abi, mcdFlashLoanTakerAddr);
    testLoan = new web3.eth.Contract(TestLoan.abi, testLoanAddr);
};

function getAbiFunction(contract, functionName) {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}

(async () => {
    await initContracts();

    // await boostWithLoan(222, getTokenJoinAddr('ETH'), '52');
    // await repayWithLoan(222, getTokenJoinAddr('ETH'), '0.4');

    await closeWithLoan(223, getTokenJoinAddr('ETH'), '1', '0.00002');

    // await openWithLeverage('200', '30', getTokenJoinAddr('BAT'));

    // await callTestLoan('1');

})();

const repayWithLoan = async (cdpId, joinAddr, daiAmount) => {
    try {
        daiAmount = web3.utils.toWei(daiAmount, 'ether');

        // cdpId, daiAmount, minPrice, exchangeType, gasCost, 0xPrice
        // address _joinAddr,
        // address _exchangeAddress,
        // bytes memory _callData
        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDFlashLoanTaker, 'repayWithLoan'),
          [[cdpId, daiAmount, 0, 2, 0, 0], joinAddr, zeroAddr, '0x0']);

        const tx = await proxy.methods['execute(address,bytes)'](mcdFlashLoanTakerAddr, data).send({
            from: account.address, gas: 2400000, gasPrice: 21100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const boostWithLoan = async (cdpId, joinAddr, amount) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDFlashLoanTaker, 'boostWithLoan'),
        [[cdpId, amount, 0, 2, 0, 0], joinAddr, zeroAddr, '0x0']);

        const tx = await proxy.methods['execute(address,bytes)'](mcdFlashLoanTakerAddr, data).send({
            from: account.address, gas: 2400000, gasPrice: 21100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const closeWithLoan = async (cdpId, joinAddr, amount, minEth) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');
        minEth = web3.utils.toWei(minEth, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDFlashLoanTaker, 'closeWithLoan'),
        [[cdpId, amount, 0, 2, 0, 0], joinAddr, zeroAddr, '0x0', minEth]);

        const tx = await proxy.methods['execute(address,bytes)'](mcdFlashLoanTakerAddr, data).send({
            from: account.address, gas: 4300000, gasPrice: 21100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const openWithLeverage = async (ethAmount, daiAmount, joinAddr) => {
    try {
        ethAmount = web3.utils.toWei(ethAmount, 'ether');
        daiAmount = web3.utils.toWei(daiAmount, 'ether');


        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDFlashLoanTaker, 'openWithLoan'),
        [[ethAmount, daiAmount, 0, 2, 0, 0], BAT_ILK, joinAddr, zeroAddr, '0x0', proxyAddr, false]);

        const tx = await proxy.methods['execute(address,bytes)'](mcdFlashLoanTakerAddr, data).send({
            from: account.address, gas: 4300000, gasPrice: 21100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const callTestLoan = async (daiAmount) => {
    try {

        const daiAddr = '0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa';

        daiAmount = web3.utils.toWei(daiAmount, 'ether');

        const tx = await testLoan.methods.takeLoan(daiAddr, daiAmount).send({
                from: account.address, gas: 4300000, gasPrice: 21100000000
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};


