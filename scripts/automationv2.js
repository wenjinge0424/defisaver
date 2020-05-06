const Web3 = require('web3');

require('dotenv').config();
const { getAbiFunction, loadAccounts, getAccounts, getProxy, fetchMakerAddresses, saverExchangeAddress, ETH_ADDRESS, nullAddress, mcdSaverProxyAddress, fundIfNeeded } = require('../test/helper.js');

const makerVersion = '1.0.6';

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
const ERC20 = require('../build/contracts/ERC20.json');
const DSSProxyActions = require('../build/contracts/DssProxyActions.json');
const Join = require('../build/contracts/Join.json');

const getCdpsAddr = '0x36a724Bd100c39f0Ea4D3A20F7097eE01A8Ff573';
const proxyRegistryAddr = '0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4';
const cdpManagerAddr = '0x5ef30b9986345249bc32d8928B7ee64DE9435E39';
// ENDE


const AutomaticProxyV2 = require("../build/contracts/AutomaticProxyV2.json");
const MCDMonitorProxyV2 = require("../build/contracts/MCDMonitorProxyV2.json");
const MCDMonitorV2 = require("../build/contracts/MCDMonitorV2.json");
const SubscriptionsV2 = require("../build/contracts/SubscriptionsV2.json");
const SubscriptionsProxyV2 = require("../build/contracts/SubscriptionsProxyV2.json");
const SaverExchange = require('../build/contracts/SaverExchange.json');


const automaticProxyAddress = '0xf970c81747BdCbAFED54ab77f859cf0DE1ecA9C9';
const subscriptionsAddress = '0x77dd93B8E49BEf255a7F8D5d8f7b7A70006A5E7b';
const subscriptionsProxyAddress = '0x06AbaC6fe0e49e57763aAa79c0D79e3e42c1894F';
const monitorAddress = '0xB08069a920F7EFC9e88c81Ee93989169be6eC879';
const monitorProxyAddress = '0x7456f4218874eAe1aF8B83a64848A1B89fEB7d7C';


const initContracts = async () => {
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.MOON_NET_NODE));
    web3 = loadAccounts(web3);
    accounts = getAccounts(web3);

    makerAddresses = await fetchMakerAddresses(makerVersion);

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

    // fund all addresses
    await fundIfNeeded(web3, accounts[0], bot.address);
    await fundIfNeeded(web3, accounts[0], owner.address);
    await fundIfNeeded(web3, accounts[0], account.address, 7);

    // ----------------------------- automatic specific -----------------------------

    monitor = new web3.eth.Contract(MCDMonitorV2.abi, monitorAddress);
    subscriptions = new web3.eth.Contract(SubscriptionsV2.abi, subscriptionsAddress);
    monitorProxy = new web3.eth.Contract(MCDMonitorProxyV2.abi, monitorProxyAddress);
    saverProxy = new web3.eth.Contract(AutomaticProxyV2.abi, automaticProxyAddress);
};

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
            from: bot.address, gas: 4500000, gasPrice: gasPrice
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const boostFor = async (cdpId, daiAmount, joinAddr, nextPrice) => {
    try {
        const tx = await monitor.methods.boostFor([cdpId, daiAmount, '0', '0', 3000000, '0'], nextPrice, joinAddr, address0, '0x0').send({
            from: bot.address, gas: 4500000, gasPrice: gasPrice
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const boost = async (cdpId, daiAmount, joinAddr, nextPrice) => {
    try {
        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(AutomaticProxyV2, 'automaticBoost'),
            [[cdpId, daiAmount, '0', '0', 3000000, '0'], joinAddr, address0, '0x0']);

        const tx = await proxy.methods['execute(address,bytes)'](automaticProxyAddress, data).send({
            from: account.address, gas: 5000000, gasPrice: gasPrice
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const repay = async (cdpId, ethAmount, joinAddr, nextPrice) => {
    try {
        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(AutomaticProxyV2, 'automaticRepay'),
            [[cdpId, ethAmount, '0', '0', 3000000, '0'], joinAddr, address0, '0x0']);

        const tx = await proxy.methods['execute(address,bytes)'](automaticProxyAddress, data).send({
            from: account.address, gas: 5000000, gasPrice: gasPrice
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

const updateChangePeriod = async (timeInDays) => {
    try {
        const tx = await monitorProxy.methods.setChangePeriod(timeInDays).send({
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

const getCdpInfo = async (cdpId, ilk) => {
    const ratio = await monitor.methods.getRatio(cdpId, 0).call();
    const info = await monitor.methods.getCdpInfo(cdpId, ilk).call();
    const price = await monitor.methods.getPrice(ilk).call();
    const automaticProxyRatio = await saverProxy.methods.getRatio(cdpId, ilk).call(); 

    return ({ratio, debt: info['1'], collateral: info['0'], price, automaticProxyRatio });
}

const getMaxDebt = async (cdpId, ilk) => {
    const maxDebt = await saverProxy.methods.getMaxDebt(cdpId, ilk).call(); 

    return maxDebt;
}

const openWbtcCdp = async () => {
    const value = web3.utils.toWei('5', 'ether');

    const web3Exchange = new web3.eth.Contract(SaverExchange.abi, saverExchangeAddress);

    await web3Exchange.methods.swapTokenToToken(ETH_ADDRESS, makerAddresses["WBTC"], value, 0, 0, nullAddress, "0x0", 0).send({from: account.address, value, gas: 3000000});

    // at this point has 5 ethers of wbtc oh account.address

    const wbtcJoin = new web3.eth.Contract(Join.abi, makerAddresses["MCD_JOIN_WBTC_A"]);
    const wbtcIlk = await wbtcJoin.methods.ilk().call();
    const daiAmount = web3.utils.toWei('50', 'ether');

    const wbtcToken = new web3.eth.Contract(ERC20.abi, makerAddresses["WBTC"]);
    const wbtcAmount = await wbtcToken.methods.balanceOf(account.address).call();

    await wbtcToken.methods.approve(proxyAddr, wbtcAmount.toString()).send({from: account.address, gas: 300000});
    
    // at this point all wbtc is approved to proxyAddr 

    const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'openLockGemAndDraw'),
     [makerAddresses['CDP_MANAGER'], makerAddresses['MCD_JUG'], makerAddresses["MCD_JOIN_WBTC_A"], makerAddresses["MCD_JOIN_DAI"], wbtcIlk, wbtcAmount.toString(), daiAmount, true]);

    await proxy.methods['execute(address,bytes)'](makerAddresses['PROXY_ACTIONS'], data).send({
            from: account.address, gas: 6700000, gasPrice: gasPrice
        });

    const cdpsAfter = await getCDPsForAddress(proxyAddr);

    console.log(cdpsAfter[cdpsAfter.length-1]);
}




(async () => {
    await initContracts();

    let cdps = await getCDPsForAddress(proxyAddr);
    // console.log(cdps);

    // await openWbtcCdp();

    // select cdp to use
    let wcdp = cdps[cdps.length-1];
    let ecdp = cdps[cdps.length-2];

    let wJoinAddr = makerAddresses["MCD_JOIN_WBTC_A"];
    let eJoinAddr = makerAddresses["MCD_JOIN_ETH_A"];

    // let joinAddr = tokenJoinAddrData['1'][cdp.ilk];

    // await updateChangePeriod(1);

    // ----------------------starters-------------------------------------
    // subscribe vault
    // await subscribeVault(wcdp.cdpId, '2000000000000000000', '25000000000000000000', '2400000000000000000', '2350000000000000000');
                                     
    // await addCaller(bot.address);
    // await addCaller('0xAED662abcC4FA3314985E67Ea993CAD064a7F5cF');
    // await addCaller('0xa5d330F6619d6bF892A5B87D80272e1607b3e34D');

    // -------------------------------------------------------------------
    const maxDebt = await getMaxDebt(wcdp.cdpId, wcdp.ilk);

    // await repay(wcdp.cdpId, '10000000', wJoinAddr, '0');
    // await boost(wcdp.cdpId, web3.utils.toWei(maxDebt, 'ether'), wJoinAddr, '0');

    // ----------------------getters-------------------------------------
    // let subscriptions = await getSubscriptions();
    // console.log(subscriptions);

    // let cdpHolder = await getCdpHolder(cdp.cdpId);
    // console.log(cdpHolder);

    let canCallBoost = await canCall(MethodEnum.Boost, wcdp.cdpId, 0);
    console.log('canCallBoost', canCallBoost);
    

    let canCallRepay = await canCall(MethodEnum.Repay, wcdp.cdpId, 0);
    console.log('canCallRepay', canCallRepay);
    // ------------------------------------------------------------------

    // let info = await getCdpInfo(wcdp.cdpId, wcdp.ilk);
    // console.log(info);

    // await repayFor(wcdp.cdpId, '10000000', wJoinAddr, '0');
    info = await getCdpInfo(wcdp.cdpId, wcdp.ilk);
    console.log('after repay', info);

    // await boostFor(wcdp.cdpId, web3.utils.toWei('500', 'ether'), wJoinAddr, '0');
    // info = await getCdpInfo(wcdp.cdpId, wcdp.ilk);
    // console.log('after boost', info);

})();







