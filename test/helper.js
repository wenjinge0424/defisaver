let { contract } = require('@openzeppelin/test-environment');
const DSProxy = contract.fromArtifact("DSProxy");
const axios = require('axios');

const nullAddress = "0x0000000000000000000000000000000000000000";
const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const saverExchangeAddress = "0x64C5cc449bD253D7fd57751c9080ACcd0216126d";

const fetchMakerAddresses = async (version, params = {}) => {
    const url = `https://changelog.makerdao.com/releases/mainnet/${version}/contracts.json`;

    const res = await axios.get(url, params);

    return res.data;
};

const loadAccounts = (web3) => {
    const account = web3.eth.accounts.privateKeyToAccount('0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d')
    web3.eth.accounts.wallet.add(account);

    return web3;
};

const getAccounts = (web3) => {
    const walletes = Object.values(web3.eth.accounts.wallet);

    return walletes.map(w => w.address);
};


const getAbiFunction = (contract, functionName) => {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
};


const getProxy = async (registry, acc) => {
    let proxyAddr = await registry.proxies(acc);
    
    if (proxyAddr === nullAddress) {
        await registry.build(acc, {from: acc});
        proxyAddr = await registry.proxies(acc);
    }

    proxy = await DSProxy.at(proxyAddr);

    return { proxy, proxyAddr };
}

module.exports = {
    getAbiFunction,
    loadAccounts,
    getAccounts,
    nullAddress,
    getProxy,
    fetchMakerAddresses,
    saverExchangeAddress,
    ETH_ADDRESS
};
