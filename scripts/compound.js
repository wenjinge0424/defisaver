

const Web3 = require('web3');

require('dotenv').config();

const DSProxy = require('../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../build/contracts/ProxyRegistryInterface.json');
const CompoundBasicProxy = require('../build/contracts/CompoundBasicProxy.json');

const proxyRegistryAddr = '0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4';
const compoundBasicProxyAddr = '0x7ca5a868eF08D97DC2Ad5D9adDaFeF10125d1a37';

const zeroAddr = '0x0000000000000000000000000000000000000000';
const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const CETH_ADDRESS = '0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5';

const DAI_ADDRESS = '0x6b175474e89094c44da98b954eedeac495271d0f';
const CDAI_ADDRESS = '0x5d3a536e4d6dbd6114cc1ead35777bab948e3643';

const MAX_UINT = '115792089237316195423570985008687907853269984665640564039457584007913129639935';


const initContracts = async () => {
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.INFURA_ENDPOINT));

    account = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY)
    web3.eth.accounts.wallet.add(account)

    registry = new web3.eth.Contract(ProxyRegistryInterface.abi, proxyRegistryAddr);

    proxyAddr = await registry.methods.proxies(account.address).call();
    proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);

};

function getAbiFunction(contract, functionName) {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}

(async () => {
    await initContracts();

    // await deposit(ETH_ADDRESS, CETH_ADDRESS, '0.01', false);
    // await withdraw(ETH_ADDRESS, CETH_ADDRESS, '0.02498541', true);
    // await borrow(DAI_ADDRESS, CDAI_ADDRESS, '0.1', false);
    await payback(DAI_ADDRESS, CDAI_ADDRESS, '0.11', true);

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
            from: account.address, value, gas: 400000, gasPrice: 5100000000});

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
            from: account.address, gas: 400000, gasPrice: 5100000000});

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
            from: account.address, gas: 700000, gasPrice: 5100000000});

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


