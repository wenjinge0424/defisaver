
const Web3 = require('web3');
const Dec = require('decimal.js');

require('dotenv').config();

const DSProxy = require('../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../build/contracts/ProxyRegistryInterface.json');
const Join = require('../build/contracts/Join.json');
const DSSProxyActions = require('../build/contracts/DSSProxyActions.json');
const GetCdps = require('../build/contracts/GetCdps.json');
const Vat = require('../build/contracts/Vat.json');
const Jug = require('../build/contracts/Jug.json');
const Spotter = require('../build/contracts/Spotter.json');
const MCDSaverProxy = require('../build/contracts/MCDSaverProxy.json');
const Faucet = require('../build/contracts/Faucet.json');
const ERC20 = require('../build/contracts/ERC20.json');
const ExchangeInterface = require('../build/contracts/SaverExchangeInterface.json');
const MonitorMigrate = require('../build/contracts/MonitorMigrateProxy.json');
const PartialMigrate = require('../build/contracts/PartialMigrationProxy.json');

const SubscriptionsProxy = require('../build/contracts/SubscriptionsProxy.json');
const Subscriptions = require('../build/contracts/Subscriptions.json');
const MCDMonitorProxy = require('../build/contracts/MCDMonitorProxy.json');
const MCDMonitor = require('../build/contracts/MCDMonitor.json');

const AutomaticMigration = require('../build/contracts/AutomaticMigration.json');
const AutomaticMigrationProxy = require('../build/contracts/AutomaticMigrationProxy.json');

const SavingsMigrationProxy = require('../build/contracts/SavingsMigration.json');

const proxyRegistryAddr = '0x64a436ae831c1672ae81f674cab8b6775df3475c';
const proxyActionsAddr = '0x3b411dbf49ad4768fe581be2cb3d14bf513116ad';
const cdpManagerAddr = '0x1476483dd8c35f25e568113c5f70249d3976ba21';
const daiJoinAddr = '0x5aa71a3ae1c0bd6ac27a1f28e1415fffb6f15b8c';
const getCdpsAddr = '0x592301a23d37c591c5856f28726af820af8e7014';
const vatAddr = '0xba987bdb501d131f766fee8180da5d81b34b69d9';
const jugAddr = '0xcbb7718c9f39d05aeede1c472ca8bf804b2f1ead';
const spotterAddr = '0x3a042de6413edb15f2784f2f97cc68c7e9750b2d';
const faucetAddr = '0x94598157fcf0715c3bc9b4a35450cce82ac57b20';

const subscriptionsProxyAddr = '0x8e5a0fb6Cd9a38bE2CAABb83744f27acd20102A5';
const subscriptionsAddr = '0xa71Ff713742420faC84Ed9Fe44db6bDF9DDFA73B';
const mcdMonitorAddr = '0xfC1Fc0502e90B7A3766f93344E1eDb906F8A75DD';
const mcdMonitorProxyAddr = '0xe414750C11DC8E47A81B31785880F8DcBc320D87';
const monitorMigrateAddr = '0x07a597cCeFc9C3976F4D34a95eA9d455a2e1A1AC';
const partialMigrateAddr = '0x951507e4671a98d5f1687bBba9BFa47d3BD9Da6a';

const exchangeAddr = '0xB14aE674cfa02d9358B0e93440d751fd9Ab2831C';

const mcdSaverProxyAddr = '0xDbfdfDBcA9f796Bf955B8B4EB2b46dBb51CaE30B';

const automaticMigrationAddr = '0x8DdA02a8485919673261dd13966CFDe41612440F';
const automaticMigrationProxyAddr = '0xe53c1293B1A47A3dE6268686E9d401b110913cD0';

const savingsMigrationProxyAddr = '0x2C6bbd638FfEE611a1C007FEe25F445437318264';

const ilkData = {
    '1' : {
        'ETH': '0x4554482d41000000000000000000000000000000000000000000000000000000',
        'BAT': '0x4241542d41000000000000000000000000000000000000000000000000000000',
        'GNT': '0x474e542d41000000000000000000000000000000000000000000000000000000',
        'OMG': '0x4f4d472d41000000000000000000000000000000000000000000000000000000',
        'ZRX': '0x5a52582d41000000000000000000000000000000000000000000000000000000',
        'REP': '0x5245502d41000000000000000000000000000000000000000000000000000000',
        'DGD': '0x4447442d41000000000000000000000000000000000000000000000000000000',
    },
    '42' : {
        'ETH': '0x4554482d41000000000000000000000000000000000000000000000000000000',
        'BAT': '0x4241542d41000000000000000000000000000000000000000000000000000000',
        'GNT': '0x474e542d41000000000000000000000000000000000000000000000000000000',
        'OMG': '0x4f4d472d41000000000000000000000000000000000000000000000000000000',
        'ZRX': '0x5a52582d41000000000000000000000000000000000000000000000000000000',
        'REP': '0x5245502d41000000000000000000000000000000000000000000000000000000',
        'DGD': '0x4447442d41000000000000000000000000000000000000000000000000000000',
    }
};

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

const tokenAddrData = {
    '1': {
        'BAT': '0x9f8cfb61d3b2af62864408dd703f9c3beb55dff7',
        'GNT': '0xc81ba844f451d4452a01bbb2104c1c4f89252907',
        'OMG': '0x441b1a74c69ee6e631834b626b29801d42076d38',
        'ZRX': '0x18392097549390502069c17700d21403ea3c721a',
        'REP': '0xc7aa227823789e363f29679f23f7e8f6d9904a9b',
        'DGD': '0x62aeec5fb140bb233b1c5612a8747ca1dc56dc1b',
    },
    '42': {
        'BAT': '0x9f8cfb61d3b2af62864408dd703f9c3beb55dff7',
        'GNT': '0xc81ba844f451d4452a01bbb2104c1c4f89252907',
        'OMG': '0x441b1a74c69ee6e631834b626b29801d42076d38',
        'ZRX': '0x18392097549390502069c17700d21403ea3c721a',
        'REP': '0xc7aa227823789e363f29679f23f7e8f6d9904a9b',
        'DGD': '0x62aeec5fb140bb233b1c5612a8747ca1dc56dc1b',
    }
};

const getTokenAddr = (type) => {
    return tokenAddrData['42'][type];
}

const getIlk = (type) => {
    return ilkData['42'][type];
}

const getTokenJoinAddr = (type) => {
    return tokenJoinAddrData['42'][type];
}

function getAbiFunction(contract, functionName) {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}

let web3,
    account,
    jug,
    oasisTrade,
    registry,
    proxy,
    join,
    vat,
    getCdps,
    proxyAddr,
    spotter,
    mcdSaverProxy,
    mcdMonitor,
    mcdMonitorProxy,
    subscriptions,
    subscriptionsProxy,
    monitorMigrate,
    partialMigrate,
    automaticMigration,
    automaticMigrationProxy,
    savingsMigrationProxy;

const initContracts = async () => {
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.KOVAN_INFURA_ENDPOINT));

    account = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY)
    web3.eth.accounts.wallet.add(account)

    // registry = new web3.eth.Contract(ProxyRegistryInterface.abi, proxyRegistryAddr);

    // proxyAddr = await registry.methods.proxies(account.address).call();
    proxy = new web3.eth.Contract(DSProxy.abi, '0x81D217E8063F5E1f002c99ef2f686576876Fade3');

    // join = new web3.eth.Contract(Join.abi, '0x92a3b1c0882e6e17aa41c5116e01b0b9cf117cf2');
    // getCdps = new web3.eth.Contract(GetCdps.abi, getCdpsAddr);
    // vat = new web3.eth.Contract(Vat.abi, vatAddr);
    // jug = new web3.eth.Contract(Jug.abi, jugAddr);
    // spotter = new web3.eth.Contract(Spotter.abi, spotterAddr);
    // mcdSaverProxy = new web3.eth.Contract(MCDSaverProxy.abi, mcdSaverProxyAddr);
    // faucet = new web3.eth.Contract(Faucet.abi, faucetAddr);
    // exchange = new web3.eth.Contract(ExchangeInterface.abi, exchangeAddr);

    // mcdMonitor = new web3.eth.Contract(MCDMonitor.abi, mcdMonitorAddr);
    // mcdMonitorProxy = new web3.eth.Contract(MCDMonitorProxy.abi, mcdMonitorProxyAddr);
    // subscriptionsProxy = new web3.eth.Contract(SubscriptionsProxy.abi, subscriptionsProxyAddr);
    // subscriptions = new web3.eth.Contract(Subscriptions.abi, subscriptionsAddr);
    // monitorMigrate = new web3.eth.Contract(MonitorMigrate.abi, monitorMigrateAddr);
    // partialMigrate = new web3.eth.Contract(PartialMigrate.abi, partialMigrateAddr);

    // automaticMigration = new web3.eth.Contract(AutomaticMigration.abi, automaticMigrationAddr);
    // automaticMigrationProxy = new web3.eth.Contract(AutomaticMigrationProxy.abi, automaticMigrationProxyAddr);

    savingsMigrationProxy = new web3.eth.Contract(SavingsMigrationProxy.abi, savingsMigrationProxyAddr);
};

(async () => {
    await initContracts();

    await migrateSavings();

    // await getAvailableDaiForMigration();

    // const usersCdps = await getCDPsForAddress(proxyAddr);
    // console.log(usersCdps);

    // await subscribeCdp(usersCdps[2].cdpId, '17500000000000000000', '22200000000000000000', '20000000000000000000', '20000000000000000000');

    // await unsubscribeCdp(usersCdps[1].cdpId);


    // let oldCdpId = '0x0000000000000000000000000000000000000000000000000000000000001abb';
    // let ethAmount = '510000000000000000';
    // let saiAmount = '57800000000000000000';
    // let minRatio = 0;
    // let migrationType = 0;
    // let currentVault = 54;
    // await migratePart(oldCdpId, ethAmount, saiAmount, minRatio, migrationType, currentVault);

    // await getRatioFromContract(usersCdps[0].cdpId);

    // await subscribeCdp(usersCdps[0].cdpId,  web3.utils.toWei('6', 'ether'),
    //     web3.utils.toWei('7.2', 'ether'),
    //     web3.utils.toWei('7', 'ether'),
    //     web3.utils.toWei('7', 'ether'));

    // await addCollateral(usersCdps[0].cdpId, 'ETH', '0.01')
    // await migrateAndSubscribe('0x0000000000000000000000000000000000000000000000000000000000001560');

    // let minRatio = web3.utils.toWei('6.0', 'ether');
    // let maxRatio = web3.utils.toWei('7.0', 'ether');
    // let optimalRatio = web3.utils.toWei('6.5', 'ether');

    // console.log(usersCdps[0].cdpId, minRatio, maxRatio, optimalRatio, optimalRatio);
    // await updateCdp(usersCdps[0].cdpId, minRatio, maxRatio, optimalRatio, optimalRatio);

    // const cdp = await subscriptions.methods.getSubscribedInfo(usersCdps[0].cdpId).call();
    // console.log("cdp:", cdp);

    // const res = await mcdSaverProxy.methods.getMaxCollateral(usersCdps[0].cdpId, getIlk('ETH')).call();

    // console.log(res);

   // await repay(usersCdps[1].cdpId, '3', 'ETH');

    // await repayFor(usersCdps[0].cdpId, web3.utils.toWei('0.1', 'ether'), getTokenJoinAddr('ETH'));
    // await boostFor(usersCdps[0].cdpId, web3.utils.toWei('0.4', 'ether'), getTokenJoinAddr('ETH'));

    // const cdpInfo = await getCdpInfo(usersCdps[0]);
    // console.log("ratio: ", cdpInfo.ratio);
    // console.log("cdp: ", cdpInfo);

    // await openCdp('BAT', '1000', '10');

    // const cdpInfo2 = await getCdpInfo(usersCdps[1]);
    // console.log(cdpInfo2.ratio, cdpInfo2.collateral /  1e18, cdpInfo2.debtWithFee / 1e18);

    // await transfer(usersCdps[1].cdpId, '0x322d58b9E75a6918f7e7849AEe0fF09369977e08');

    // const res = await getCollateralInfo(getIlk('REP'));

    // console.log(res);

    // await faucet.methods.gulp(getTokenAddr('GNT')).send({from: account.address, gas: 300000});


})();

const migrateSavings = async () => {
    try {
        console.log('preparing');

        data = web3.eth.abi.encodeFunctionCall(getAbiFunction(SavingsMigrationProxy, 'migrateSavings'),
            []);

        console.log('data', data);

        const tx = await proxy.methods['execute(address,bytes)'](savingsMigrationProxyAddr, data).send({
            from: account.address, gas: 4000000, nonce: 179, gasPrice: 4100000000
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const repayFor = async (cdpId, amount, collateralJoin) => {
    try {
        const tx = await mcdMonitor.methods.repayFor(cdpId, amount, collateralJoin).send({
            from: account.address, gas: 9000000
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const boostFor = async (cdpId, amount, collateralJoin) => {
    try {
        const tx = await mcdMonitor.methods.boostFor(cdpId, amount, collateralJoin).send({
            from: account.address, gas: 9000000
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const subscribeCdp = async (cdpId, minRatio, maxRatio, optimalRatioBoost, optimalRatioRepay) => {
    try {
        data = web3.eth.abi.encodeFunctionCall(getAbiFunction(SubscriptionsProxy, 'subscribe'),
            [cdpId, minRatio, maxRatio, optimalRatioBoost, optimalRatioRepay, subscriptionsAddr]);

        const tx = await proxy.methods['execute(address,bytes)'](subscriptionsProxyAddr, data).send({
            from: account.address, gas: 9000000
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const unsubscribeCdp = async (cdpId) => {
    try {
        data = web3.eth.abi.encodeFunctionCall(getAbiFunction(SubscriptionsProxy, 'unsubscribe'),
            [cdpId, subscriptionsAddr]);

        const tx = await proxy.methods['execute(address,bytes)'](subscriptionsProxyAddr, data).send({
            from: account.address, gas: 9000000
        });

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const updateCdp = async (cdpId, minRatio, maxRatio, optimalRatioBoost, optimalRatioRepay) => {
    try {
        data = web3.eth.abi.encodeFunctionCall(getAbiFunction(SubscriptionsProxy, 'update'),
            [cdpId, minRatio, maxRatio, optimalRatioBoost, optimalRatioRepay, subscriptionsAddr]);

        const tx = await proxy.methods['execute(address,bytes)'](subscriptionsProxyAddr, data).send({
            from: account.address, gas: 9000000
        });

        console.log(tx);

        const cdp = await subscriptions.methods.getSubscribedInfo(cdpId).call();
        console.log("cdp:", cdp);
    } catch(err) {
        console.log(err);
    }
}

const openCdp = async (type, collateralAmount, daiAmount) => {
    try {

        daiAmount = web3.utils.toWei(daiAmount, 'ether');
        collateralAmount = web3.utils.toWei(collateralAmount, 'ether'); //TODO: to collateral precision

        let value = 0;
        let data = null;

        if (type === 'ETH') {
            data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'openLockETHAndDraw'),
            [cdpManagerAddr, jugAddr, getTokenJoinAddr(type), daiJoinAddr, getIlk(type), daiAmount]);

            value = collateralAmount;
        } else {
            await approveToken(type);

            data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'openLockGemAndDraw'),
            [cdpManagerAddr, jugAddr, getTokenJoinAddr(type), daiJoinAddr, getIlk(type), collateralAmount, daiAmount, true]);
        }

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({
            from: account.address, gas: 900000, value});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const addCollateral = async (cdpId, type, collateralAmount) => {
    try {
        collateralAmount = web3.utils.toWei(collateralAmount, 'ether'); //TODO: to collateral precision

        let data = null;
        let value = 0;

        if (type === 'ETH') {
            data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'lockETH'),
            [cdpManagerAddr, getTokenJoinAddr(type), cdpId]);

            value = collateralAmount;
        } else {
            await approveToken(type);

            data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'lockGem'),
            [cdpManagerAddr, getTokenJoinAddr(type), cdpId, collateralAmount, true]);
        }

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({from: account.address, value, gas: 900000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const freeCollateral = async (cdpId, type, collateralAmount) => {
    try {
        collateralAmount = web3.utils.toWei(collateralAmount, 'ether'); //TODO: to collateral precision

        let data = null;
        let value = 0;

        if (type === 'ETH') {
            data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'freeETH'),
            [cdpManagerAddr, getTokenJoinAddr(type), cdpId, collateralAmount]);
        } else {
            data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'freeGem'),
            [cdpManagerAddr, getTokenJoinAddr(type), cdpId, collateralAmount]);
        }

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({from: account.address, value, gas: 900000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const generateDai = async (cdpId, daiAmount) => {
    try {
        daiAmount = web3.utils.toWei(daiAmount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'draw'),
        [cdpManagerAddr, jugAddr, daiJoinAddr, cdpId, daiAmount]);

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({from: account.address, gas: 900000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
}

const drawDai = async (cdpId, daiAmount) => {
    try {
        daiAmount = web3.utils.toWei('1', 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'draw'),
          [cdpManagerAddr, jugAddr, daiJoinAddr, cdpId, daiAmount]);

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({
            from: account.address, gas: 900000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};


const payback = async (cdpId, daiAmount) => {
    try {
        await approveToken('DAI');

        daiAmount = web3.utils.toWei('1', 'ether');

        // TODO: wipeAll when we want the whole debt payed

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'wipe'),
          [cdpManagerAddr, getTokenJoinAddr('DAI'), cdpId, daiAmount]);

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({
            from: account.address, gas: 900000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const transfer = async (cdpId, receiversAddr) => {
    try {
        // TODO: receiversAddr check if not 0x0

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'give'),
          [cdpManagerAddr, cdpId, receiversAddr]);

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({
            from: account.address, gas: 900000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};


const boost = async (cdpId, amount, type) => {
    try {
        const daiAmount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDSaverProxy, 'boost'),
          [cdpId, getTokenJoinAddr(type), daiAmount, 0, 2, 0]);

        const tx = await proxy.methods['execute(address,bytes)'](mcdSaverProxyAddr, data).send({
            from: account.address, gas: 1900000});

        // console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const repay = async (cdpId, amount, type) => {
    try {
        console.log("Regular repay");
        const ethAmount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDSaverProxy, 'repay'),
          [cdpId, getTokenJoinAddr(type), ethAmount, 0, 2, 0]);

        const tx = await proxy.methods['execute(address,bytes)'](mcdSaverProxyAddr, data).send({
            from: account.address, gas: 1900000});

        // console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const getRatioFromContract = async (cdpId) => {
    try {
        const ratio = await mcdSaverProxy.methods.getMaxCollateral(cdpManagerAddr, cdpId, getIlk('ETH')).call();

        console.log(ratio / 1e18);
    } catch(err) {
        console.log(err);
    }
};

const migrateAndSubscribe = async (oldCdpId) => {
    try {

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MonitorMigrate, 'migrateAndSubscribe'),
          [oldCdpId]);

        const tx = await proxy.methods['execute(address,bytes)'](monitorMigrateAddr, data).send({
            from: account.address, gas: 2200000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const migratePart = async (oldCdpId, ethAmount, saiAmount, minRatio, migrationType, currentVault) => {
    try {

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(PartialMigrate, 'migratePart'),
          [oldCdpId, ethAmount, saiAmount, minRatio, migrationType, currentVault]);

        const tx = await proxy.methods['execute(address,bytes)'](partialMigrateAddr, data).send({
            from: account.address, gas: 2200000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

// if CDP debt is < 20 SAI migration fails
const getAvailableDaiForMigration = async () => {
    const saiIlk = '0x5341490000000000000000000000000000000000000000000000000000000000';

    //TODO: based on which network you're on should change
    const scdMcdMigrationAddr = '0x411b2faa662c8e3e5cf8f01dfdae0aee482ca7b0';

    const specialCDP = await vat.methods.urns(saiIlk, scdMcdMigrationAddr).call();

    return Dec(specialCDP.ink).sub(1000);
};


const subscribeForMigration = async (cdpId, type) => {
    try {

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(AutomaticMigrationProxy, 'subscribe'),
          [cdpId, type]);

        const tx = await proxy.methods['execute(address,bytes)'](automaticMigrationProxyAddr, data).send({
            from: account.address, gas: 2200000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};


/****************************** INFO FUNCTIONS *************************************/



const getCdpInfo = async (cdp) => {
    try {

        const ilkInfo = await getCollateralInfo(cdp.ilk);
        const urn = await vat.methods.urns(cdp.ilk, cdp.urn).call();

        const collateral = Dec(urn.ink);
        const debt = Dec(urn.art);

        const debtWithFee = debt.times(ilkInfo.currentRate).div(1e27);

        const stabilityFee = debtWithFee.sub(debt);

        const ratio = collateral.times(ilkInfo.price).div(debtWithFee).times(100);

        const liquidationPrice = debt.times(ilkInfo.liquidationRatio).div(collateral);

        return {
            id: cdp.cdpId,
            type: cdp.ilk,
            collateral,
            debt,
            debtWithFee, // debt + stabilityFee
            stabilityFee: stabilityFee.div(1e18),
            ratio,
            liquidationPrice
        };
    } catch(err) {
        console.log(err);
    }
};

// either ilk or cdpId, if cdpId send bytes32(0) for ilk
const getCollateralInfo = async (ilk, cdpId) => {
    try {
        const ilkInfo = await subscriptions.methods.getIlkInfo(ilk, cdpId).call();

        let par = Dec(ilkInfo.par).div(1e27);
        const spot = Dec(ilkInfo.spot).div(1e27);
        const mat = Dec(ilkInfo.mat).div(1e27);

        const price = spot.times(par).times(mat);

        return {
            currentRate: ilkInfo.rate,
            price, // TODO: check if true
            minAmountForCdp: ilkInfo.dust,
            currAmountGlobal: ilkInfo.art, //total debt TODO: * rate
            maxAmountGlobal: ilkInfo.line,
            liquidationRatio: mat,
        }
    } catch(err) {
        console.log(err);
    }
};

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

const calcAfterRatio = async (type, collateral, debt) => {
    const collateralInfo = getCollateralInfo(getIlk(type));

    return (collateral * collateralInfo.price) / debt;
};

const getStabilityFee = async (ilk) => {
    try {
        const secondsPerYear = 60 * 60 * 24 * 365;
        const stabilityFee = await jug.methods.ilks(ilk).call();

        /*
        duty = new BigNumber(duty.toString()).dividedBy(RAY);
        BigNumber.config({ POW_PRECISION: 100 });
        return duty
            .pow(secondsPerYear)
            .minus(1)
            .toNumber();
        */

        return stabilityFee.duty; //this is per second, we need per year
    } catch(err) {
        console.log(err);
    }
};

// HELPER FUNCTIONS

const approveToken = async (type) => {
    const token = new web3.eth.Contract(ERC20.abi, getTokenAddr(type));

    const allowance = await token.methods.allowance(account.address, proxyAddr).call();

    console.log(allowance.toString());

   if (allowance.toString() === '0') {
        await token.methods.approve(proxyAddr, web3.utils.toWei('10000000000000', 'ether')).send({from: account.address, gas: 100000});
   }
};

const transferToProxy = async (type, collateralAmount) => {
    const token = new web3.eth.Contract(ERC20.abi, getTokenAddr(type));

    await token.methods.transfer(proxyAddr, collateralAmount).send({from: account.address, gas: 500000});
};

const swap = async () => {
    try {
        const daiAmount = web3.utils.toWei('100', 'ether');
        // const token = new web3.eth.Contract(ERC20.abi, '0xC4375B7De8af5a38a93548eb8453a498222C4fF2');

        // await token.methods.approve(oasisTradeAddr, web3.utils.toWei('10000000000000', 'ether')).send({from: account.address, gas: 100000});

        // _amount, _src, _dest, _exchangeType
        const res = await exchange.methods.getBestPrice(daiAmount,
             '0xC4375B7De8af5a38a93548eb8453a498222C4fF2', '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', 0).call();

        console.log(res);
    } catch(err) {
        console.log(err);
    }
}
