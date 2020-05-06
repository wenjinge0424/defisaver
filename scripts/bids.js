

const Web3 = require('web3');

require('dotenv').config();

const DSProxy = require('../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../build/contracts/ProxyRegistryInterface.json');
const BidProxy = require('../build/contracts/BidProxy.json');

const bidsProxy = '0x49f0D7B5cAD919f88C019Ca748A27383EA0f4Bbe';
const proxyRegistryAddr = '0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4';

const initContracts = async () => {
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.MOON_NET_NODE));

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

    await collateralBid(4823, true, '0.20');
})();



const collateralBid = async (bidId, isEth, amount) => {
    try {
        amount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(BidProxy, 'collateralBid'),
        [bidId, isEth, amount]);

        const tx = await proxy.methods['execute(address,bytes)'](bidsProxy, data).send({
            from: account.address, gas: 300000, gasPrice: 8110000000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};




