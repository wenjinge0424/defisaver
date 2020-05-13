let { contract } = require('@openzeppelin/test-environment');
const DSProxy = contract.fromArtifact("DSProxy");
const axios = require('axios');

const nullAddress = "0x0000000000000000000000000000000000000000";
const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const saverExchangeAddress = "0xc21dc5A1b919088F308e0b02243Aaf64c060Dbd0";
const mcdSaverProxyAddress = "0xa292832ACF0b0226E378E216A982fA966eaA7EBc";

const ERC20 = contract.fromArtifact("ERC20");

const fetchMakerAddresses = async (version, params = {}) => {
    const url = `https://changelog.makerdao.com/releases/mainnet/${version}/contracts.json`;

    const res = await axios.get(url, params);

    // console.log(res.data);

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

const fundIfNeeded = async (web3, fundAccAddress, accAddress, minBal=5, addBal=10) => {
    const weiBal = await web3.eth.getBalance(accAddress);
    const bal = web3.utils.fromWei(weiBal.toString(), 'ether')

    console.log(`Funding ${accAddress}, current balance: ${bal.toString()} from: ${fundAccAddress}`);
    if (parseFloat(bal) < minBal) {
        await web3.eth.sendTransaction({gas: 21000, from: fundAccAddress, to: accAddress, value: web3.utils.toWei(addBal.toString(), "ether")});
    }
};

const getProxy = async (registry, acc) => {
    let proxyAddr = await registry.proxies(acc);

    if (proxyAddr === nullAddress) {
        await registry.build(acc, {from: acc});
        proxyAddr = await registry.proxies(acc);
    }

    proxy = await DSProxy.at(proxyAddr);

    return { proxy, proxyAddr };
};

const getBalance = async (web3, account, tokenAddress) => {
    if (tokenAddress === ETH_ADDRESS) {
        const ethBalance = await web3.eth.getBalance(account);
        return ethBalance.toString();
    }

    const erc20 = await ERC20.at(tokenAddress);

    const tokenBalance = await erc20.balanceOf(account);
    return tokenBalance.toString();
};

const approve = async (web3, tokenAddress, from, to, amount) => {
    if (tokenAddress === ETH_ADDRESS) {
        return;
    }

    if (!amount) {
        amount = '115792089237316195423570985008687907853269984665640564039457584007913129639935';
    }

    const erc20 = new web3.eth.Contract(ERC20.abi, tokenAddress);
    await erc20.methods.approve(to, amount).send({from, gas: 100000});
};

module.exports = {
    getAbiFunction,
    loadAccounts,
    getAccounts,
    getBalance,
    approve,
    getProxy,
    fetchMakerAddresses,
    fundIfNeeded,
    nullAddress,
    saverExchangeAddress,
    mcdSaverProxyAddress,
    ETH_ADDRESS,
};
