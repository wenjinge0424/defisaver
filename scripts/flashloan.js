

const Web3 = require('web3');

require('dotenv').config();

const DSProxy = require('../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../build/contracts/ProxyRegistryInterface.json');
const DSSProxyActions = require('../build/contracts/DSSProxyActions.json');
const MCDSaverFlashProxy = require('../build/contracts/MCDSaverFlashProxy.json');

const proxyRegistryAddr = '0x64a436ae831c1672ae81f674cab8b6775df3475c';
const mcdSaverFlashProxyAddr = '0x6e0b3Ea654247aDf5A2E73d7FAD9628FBd9A094D';

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

    console.log(account.address);

    registry = new web3.eth.Contract(ProxyRegistryInterface.abi, proxyRegistryAddr);

    proxyAddr = await registry.methods.proxies(account.address).call();
    proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);

    mcdSaverFlashProxy = new web3.eth.Contract(MCDSaverFlashProxy.abi, mcdSaverFlashProxyAddr);
};

function getAbiFunction(contract, functionName) {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}

(async () => {
    await initContracts();

    await boostWithLoan(222, getTokenJoinAddr('ETH'), '20');

})();

const repayWithLoan = async (cdpId, joinAddr, daiAmount) => {
    try {
        daiAmount = web3.utils.toWei(daiAmount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDSaverFlashProxy, 'getLoan'),
          [cdpId, joinAddr, daiAmount, 0, 4, 0, true]);

        const tx = await proxy.methods['execute(address,bytes)'](mcdSaverFlashProxyAddr, data).send({
            from: account.address, gas: 2400000, gasPrice: 21100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const boostWithLoan = async (cdpId, joinAddr, amount) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDSaverFlashProxy, 'getLoan'),
          [cdpId, joinAddr, amount, 0, 4, 0, false]);

        const tx = await proxy.methods['execute(address,bytes)'](mcdSaverFlashProxyAddr, data).send({
            from: account.address, gas: 2400000, gasPrice: 21100000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};
