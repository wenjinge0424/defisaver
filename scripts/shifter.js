

const Web3 = require('web3');

require('dotenv').config();

const DSProxy = require('../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../build/contracts/ProxyRegistryInterface.json');

const LoanShifterTaker = require('../build/contracts/LoanShifterTaker.json');

const ETH_ILK = '0x4554482d41000000000000000000000000000000000000000000000000000000';
const BAT_ILK = '0x4241542d41000000000000000000000000000000000000000000000000000000';

const nullAddress = '0x0000000000000000000000000000000000000000';

const loanShifterTakerAddr = '0x51826e32c322634120ef9f3f2d3b62cfdc31e80b';
const mcdEthJoin = '0x2F0b23f53734252Bda2277357e97e1517d6B042A';


const {
    fetchMakerAddresses,
} = require('../test/helper.js');

const getTokenJoinAddr = (type) => {
    return tokenJoinAddrData['42'][type];
};

const makerVersion = "1.0.6";


const initContracts = async () => {

    makerAddresses = await fetchMakerAddresses(makerVersion);

    web3 = new Web3(new Web3.providers.HttpProvider(process.env.INFURA_ENDPOINT));

    account = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY)
    web3.eth.accounts.wallet.add(account)

    registry = new web3.eth.Contract(ProxyRegistryInterface.abi, makerAddresses["PROXY_REGISTRY"]);

    proxyAddr = await registry.methods.proxies(account.address).call();
    proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);


};

function getAbiFunction(contract, functionName) {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}

(async () => {
    await initContracts();

    await mergeVaults();
})();

const mergeVaults = async () => {

    const cdp1 = '6770';
    const cdp2 = '6629';

    const moveData = web3.eth.abi.encodeFunctionCall(getAbiFunction(LoanShifterTaker, 'moveLoan'),
    [
     [0, 0, false, web3.utils.toWei('0.1', 'ether'), web3.utils.toWei('10', 'ether'), makerAddresses["MCD_DAI"], mcdEthJoin, mcdEthJoin, cdp1, cdp2],
    // [nullAddress, nullAddress, 0, 0, 0, 0, nullAddress, "0x0", 0]
    ]);

    await proxy.methods['execute(address,bytes)']
     (loanShifterTakerAddr, moveData).send({from: account.address, gas: 500000, gasPrice: 46100000000});
};

