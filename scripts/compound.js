

const Web3 = require('web3');

require('dotenv').config();

const DSProxy = require('../../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../../build/contracts/ProxyRegistryInterface.json');
const CompoundBasicProxy = require('../../build/contracts/CompoundBasicProxy.json');
const CompoundSaverProxy = require('../../build/contracts/CompoundSaverProxy.json');
const CTokenInterface = require('../../build/contracts/CTokenInterface.json');
const CompoundFlashLoanTaker = require('../../build/contracts/CompoundFlashLoanTaker.json');
const BridgeFlashLoanTaker = require('../../build/contracts/BridgeFlashLoanTaker.json');
const CompoundLoanInfo = require('../../build/contracts/CompoundLoanInfo.json');

const proxyRegistryAddr = '0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4';
const compoundBasicProxyAddr = '0x0F1e33A36fA6a33Ea01460F04c6D8F1FAc2186E3';
const compoundSaverProxyAddr = '0xff97C79d207FC3D7a51531d0fa93581cf8E0105D';
const compoundFlashLoanTakerAddr = '0x2f59bf2779c9AB965ca6BF63F5Eb1504C5B36D38';
const bridgeFlashLoanTakerAddr = '0x4b922507b808d3895c2213a2b4c4720756b4d9e0';
const compoundLoanInfoAddr = '0x9d16742a47490A47d3f85E06fcfD52aCA3E5A88d';

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
};

function getAbiFunction(contract, functionName) {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}

(async () => {
    await initContracts();

    // await deposit(ETH_ADDRESS, CETH_ADDRESS, '0.05', false);
    await withdraw(ETH_ADDRESS, CETH_ADDRESS, '0.015', true);
    // await borrow(DAI_ADDRESS, CDAI_ADDRESS, '2.6', false);
    // await payback(DAI_ADDRESS, CDAI_ADDRESS, '0.5', true);

    // await repayWithLoan('0.015', CETH_ADDRESS, CDAI_ADDRESS);

    // await boostWithLoan('0.5', CETH_ADDRESS, CDAI_ADDRESS);

    // await boost('5', CETH_ADDRESS, CDAI_ADDRESS);

    // await bridgeMaker2Compound('6770', getTokenJoinAddr('ETH'), CETH_ADDRESS);

    // await bridgeCompound2Maker('6770', getTokenJoinAddr('ETH'), CETH_ADDRESS);
})();

// User needs to approve the DSProxy to pull the _tokenAddr tokens
//function deposit(address _tokenAddr, address _cTokenAddr, uint _amount, bool _inMarket) public payable {
const deposit = async (tokenAddr, cTokenAddr, amount, alreadyInMarket) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundBasicProxy, 'deposit'),
          [tokenAddr, cTokenAddr, amount, alreadyInMarket]);

        let value = '0';

        if (tokenAddr === ETH_ADDRESS) {
            value = amount;
        }

        const tx = await proxy.methods['execute(address,bytes)'](compoundBasicProxyAddr, data).send({
            from: account.address, value, gas: 400000, gasPrice: 8100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

// withdraw(address _tokenAddr, address _cTokenAddr, uint _amount, bool _isCAmount)
const withdraw = async (tokenAddr, cTokenAddr, amount, isCAmount) => {
    try {
        if (isCAmount) {
            amount = (amount * 1e8).toString();
        } else {
            amount = web3.utils.toWei(amount, 'ether');
        }

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundBasicProxy, 'withdraw'),
          [tokenAddr, cTokenAddr, amount, isCAmount]);

        const tx = await proxy.methods['execute(address,bytes)'](compoundBasicProxyAddr, data).send({
            from: account.address, gas: 400000, gasPrice: 9100000000 });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

// function borrow(address _tokenAddr, address _cTokenAddr, uint _amount, bool _inMarket)
const borrow = async (tokenAddr, cTokenAddr, amount, alreadyInMarket) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundBasicProxy, 'borrow'),
          [tokenAddr, cTokenAddr, amount, alreadyInMarket]);

        const tx = await proxy.methods['execute(address,bytes)'](compoundBasicProxyAddr, data).send({
            from: account.address, gas: 700000, gasPrice: 8100000000, nonce: 3660});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

// User needs to approve the DSProxy to pull the _tokenAddr tokens
// payback(address _tokenAddr, address _cTokenAddr, uint _amount, bool _wholeDebt)
//
const payback = async (tokenAddr, cTokenAddr, amount, wholeDebt) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundBasicProxy, 'payback'),
            [tokenAddr, cTokenAddr, amount, wholeDebt]);

        let value = '0';

        if (tokenAddr === ETH_ADDRESS) {
            value = amount;
        }

        const tx = await proxy.methods['execute(address,bytes)'](compoundBasicProxyAddr, data).send({
            from: account.address, value, gas: 500000, gasPrice: 5100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

// function repay(
//     uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
//     address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
//     bytes calldata _callData
const repay = async (amount, cCollAddress, cBorrowAddress) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundSaverProxy, 'repay'),
        [[amount, 0, 3, 0, 0], [cCollAddress, cBorrowAddress, zeroAddr], "0x0"]);

        const tx = await proxy.methods['execute(address,bytes)'](compoundSaverProxyAddr, data).send({
            from: account.address, gas: 1300000, gasPrice: 5100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

// function boost(
//     uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
//     address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
//     bytes calldata _callData
const boost = async (amount, cCollAddress, cBorrowAddress) => {
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

// function repayWithLoan(
//     uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
//     address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
//     bytes calldata _callData
const repayWithLoan = async (amount, cCollAddress, cBorrowAddress) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundFlashLoanTaker, 'repayWithLoan'),
        [[amount, 0, 3, 0, 0], [cCollAddress, cBorrowAddress, zeroAddr], "0x0"]);

        const tx = await proxy.methods['execute(address,bytes)'](compoundFlashLoanTakerAddr, data).send({
            from: account.address, gas: 1900000, gasPrice: 5100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

// function boostWithLoan(
//     uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
//     address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
//     bytes calldata _callData
const boostWithLoan = async (amount, cCollAddress, cBorrowAddress) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundFlashLoanTaker, 'boostWithLoan'),
        [[amount, 0, 3, 0, 0], [cCollAddress, cBorrowAddress, zeroAddr], "0x0"]);

        const tx = await proxy.methods['execute(address,bytes)'](compoundFlashLoanTakerAddr, data).send({
            from: account.address, gas: 1900000, gasPrice: 5100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};


const bridgeMaker2Compound = async (cdpId, joinAddr, cAddr) => {
    try {
        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(BridgeFlashLoanTaker, 'maker2Compound'),
            [cdpId, joinAddr, cAddr]);

        const tx = await proxy.methods['execute(address,bytes)'](bridgeFlashLoanTakerAddr, data).send({
            from: account.address, gas: 1500000, gasPrice: 7100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const bridgeCompound2Maker = async (cdpId, joinAddr, cAddr) => {
    try {
        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(BridgeFlashLoanTaker, 'compound2Maker'),
            [cdpId, joinAddr, cAddr]);

        const tx = await proxy.methods['execute(address,bytes)'](bridgeFlashLoanTakerAddr, data).send({
            from: account.address, gas: 1500000, gasPrice: 7100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};



