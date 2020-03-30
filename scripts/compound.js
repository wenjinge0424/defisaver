

const Web3 = require('web3');

require('dotenv').config();

const DSProxy = require('../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../build/contracts/ProxyRegistryInterface.json');
const CompoundBasicProxy = require('../build/contracts/CompoundBasicProxy.json');

const proxyRegistryAddr = '0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4';
const compoundBasicProxyAddr = '0x33b71F9B6a91F9Aac88703f722cCECFf32BeE741';

const zeroAddr = '0x0000000000000000000000000000000000000000';
const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const CETH_ADDRESS = '0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5';


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

    // await deposit(ETH_ADDRESS, CETH_ADDRESS, '0.001', true);
    await withdraw(ETH_ADDRESS, CETH_ADDRESS, '0.02498541', true);

})();

//function deposit(address _tokenAddr, address _cTokenAddr, uint _amount, bool _inMarket) public payable {
const deposit = async (tokenAddr, cTokenAddr, amount, inMarket) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundBasicProxy, 'deposit'),
          [tokenAddr, cTokenAddr, amount, inMarket]);

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
