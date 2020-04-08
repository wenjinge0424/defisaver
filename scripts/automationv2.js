const Web3 = require('web3');

require('dotenv').config();

// configs
const gasPrice = 9200000000;
var MethodEnum = {
  Boost: 0,
  Repay: 1,
};
const address0 = '0x0000000000000000000000000000000000000000';

const tokenJoinAddrData = {
    '1': {
        '0x4554482d41000000000000000000000000000000000000000000000000000000': '0x2f0b23f53734252bda2277357e97e1517d6b042a',
        '0x4241542d41000000000000000000000000000000000000000000000000000000': '0x3d0b1912b66114d4096f48a8cee3a56c231772ca',
    }
}


// MAKER STUFF
const GetCdps = require('../build/contracts/GetCdps.json');
const DSProxy = require('../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../build/contracts/ProxyRegistryInterface.json');

const getCdpsAddr = '0x36a724Bd100c39f0Ea4D3A20F7097eE01A8Ff573';
const proxyRegistryAddr = '0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4';
const cdpManagerAddr = '0x5ef30b9986345249bc32d8928B7ee64DE9435E39';
// ENDE


const AutomaticProxyV2 = require("../build/contracts/AutomaticProxyV2.json");
const MCDMonitorProxyV2 = require("../build/contracts/MCDMonitorProxyV2.json");
const MCDMonitorV2 = require("../build/contracts/MCDMonitorV2.json");
const SubscriptionsV2 = require("../build/contracts/SubscriptionsV2.json");
const SubscriptionsProxyV2 = require("../build/contracts/SubscriptionsProxyV2.json");


const automaticProxyAddress = '0xC563aCE6FACD385cB1F34fA723f412Cc64E63D47';
const subscriptionsAddress = '0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a';
const subscriptionsProxyAddress = '0xd6f2125bF7FE2bc793dE7685EA7DEd8bff3917DD';
const monitorAddress = '0x86E29E91989be4491F9cF14c8c8030136487b5cd';
const monitorProxyAddress = '0x47d9f61bADEc4378842d809077A5e87B9c996898';


const initContracts = async () => {
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.INFURA_ENDPOINT));

    registry = new web3.eth.Contract(ProxyRegistryInterface.abi, proxyRegistryAddr);
    getCdps = new web3.eth.Contract(GetCdps.abi, getCdpsAddr);

    account = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY)
    web3.eth.accounts.wallet.add(account)
    proxyAddr = await registry.methods.proxies(account.address).call();
    proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);

    bot = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY_BOT)
    web3.eth.accounts.wallet.add(bot)
    proxyAddrBot = await registry.methods.proxies(bot.address).call();
    proxyBot = new web3.eth.Contract(DSProxy.abi, proxyAddrBot);

    owner = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY_OWNER)
    web3.eth.accounts.wallet.add(owner)
    proxyAddrOwner = await registry.methods.proxies(owner.address).call();
    proxyOwner = new web3.eth.Contract(DSProxy.abi, proxyAddrOwner);

    // ----------------------------- automatic specific -----------------------------

    monitor = new web3.eth.Contract(MCDMonitorV2.abi, monitorAddress);
    subscriptions = new web3.eth.Contract(SubscriptionsV2.abi, subscriptionsAddress);
    monitorProxy = new web3.eth.Contract(MCDMonitorProxyV2.abi, monitorProxyAddress);
};

function getAbiFunction(contract, functionName) {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}

// sending tx

const subscribeVault = async (cdpId, minRatio, maxRatio, optimalRatioBoost, optimalRatioRepay) => {
    try {
        data = web3.eth.abi.encodeFunctionCall(getAbiFunction(SubscriptionsProxyV2, 'subscribe'),
            [cdpId, minRatio, maxRatio, optimalRatioBoost, optimalRatioRepay, true, true, subscriptionsAddress]);

        const tx = await proxy.methods['execute(address,bytes)'](subscriptionsProxyAddress, data).send({
            from: account.address, gas: 500000, gasPrice: gasPrice
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const repayFor = async (cdpId, ethAmount, joinAddr, nextPrice) => {
    try {
        const tx = await monitor.methods.repayFor([cdpId, ethAmount, '0', '0', 3000000, '0'], nextPrice, joinAddr, address0, '0x0').send({
            from: bot.address, gas: 3500000, gasPrice: gasPrice
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const boostFor = async (cdpId, daiAmount, joinAddr, nextPrice) => {
    try {
        const tx = await monitor.methods.boostFor([cdpId, daiAmount, '0', '0', 3000000, '0'], nextPrice, joinAddr, address0, '0x0').send({
            from: bot.address, gas: 3500000, gasPrice: gasPrice
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}


const addCaller = async (callerAddress) => {
    try {
        const tx = await monitor.methods.addCaller(callerAddress).send({
            from: owner.address, gas: 100000, gasPrice: gasPrice
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}



// getters

const getCDPsForAddress = async (proxyAddr) => {
    const cdps = await getCdps.methods.getCdpsAsc(cdpManagerAddr, proxyAddr).call();

    let usersCdps = [];

    cdps.ids.forEach((id, i) => {
        usersCdps.push({
            cdpId: id,
            urn: cdps.urns[i],
            ilk: cdps.ilks[i]
        });
    });

    return usersCdps;
}


const getSubscriptions = async () => {
    const cdps = await subscriptions.methods.getSubscribers().call();

    let usersCdps = [];

    for (var i = cdps.length - 1; i >= 0; i--) {
        let cdp = cdps[i];
        usersCdps.push({
            cdpId: cdp.cdpId,
            optimalRatioRepay: cdp.optimalRatioRepay,
            optimalRatioBoost: cdp.optimalRatioBoost,
            minRatio: cdp.minRatio,
            maxRatio: cdp.maxRatio,
            boostEnabled: cdp.boostEnabled,
            nextPriceEnabled: cdp.nextPriceEnabled,
            owner: cdp.owner
        });
    }

    return usersCdps;
}

const getCdpHolder = async (cdpId) => {
    const cdp = await subscriptions.methods.getCdpHolder(cdpId).call();

    return {
        subscribed: cdp.subscribed,
        cdpId: cdp['1'].cdpId,
        optimalRatioRepay: cdp['1'].optimalRatioRepay,
        optimalRatioBoost: cdp['1'].optimalRatioBoost,
        minRatio: cdp['1'].minRatio,
        maxRatio: cdp['1'].maxRatio,
        boostEnabled: cdp['1'].boostEnabled,
        nextPriceEnabled: cdp['1'].nextPriceEnabled,
        owner: cdp['1'].owner
    };
}

const canCall = async (method, cdpId, nextPrice) => {
    const response = await monitor.methods.canCall(method, cdpId, nextPrice).call();

    return response;
}


(async () => {
    await initContracts();

    let cdps = await getCDPsForAddress(proxyAddr);
    console.log(cdps);

    // select cdp to use
    let cdp = cdps[3];
    let joinAddr = tokenJoinAddrData['1'][cdp.ilk];

    // ----------------------starters-------------------------------------
    // subscribe vault
    await subscribeVault(cdp.cdpId, '2000000000000000000', '25000000000000000000', '2400000000000000000', '2350000000000000000');
                                     
    // await addCaller(bot.address);
    // -------------------------------------------------------------------

    // ----------------------getters-------------------------------------
    // let subscriptions = await getSubscriptions();
    // console.log(subscriptions);

    // let cdpHolder = await getCdpHolder(cdp.cdpId);
    // console.log(cdpHolder);

    // let canCallBoost = await canCall(MethodEnum.Boost, cdp.cdpId, 0);
    // console.log('canCallBoost', canCallBoost);

    // let canCallRepay = await canCall(MethodEnum.Repay, cdp.cdpId, 0);
    // console.log('canCallRepay', canCallRepay);
    // ------------------------------------------------------------------

    // await repayFor(cdp.cdpId, web3.utils.toWei('0.1', 'ether'), joinAddr, '0');
    // await boostFor(cdp.cdpId, web3.utils.toWei('20', 'ether'), joinAddr, '0');
})();







