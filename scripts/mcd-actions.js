
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
const OasisTrade = require('../build/contracts/OasisTradeWrapper.json');
const ExchangeInterface = require('../build/contracts/SaverExchangeInterface.json');

const SubscriptionsProxy = require('../build/contracts/SubscriptionsProxy.json');
const Subscriptions = require('../build/contracts/Subscriptions.json');
const MCDMonitorProxy = require('../build/contracts/MCDMonitorProxy.json');
const MCDMonitor = require('../build/contracts/MCDMonitor.json');

const proxyRegistryAddr = '0x64a436ae831c1672ae81f674cab8b6775df3475c';
const proxyActionsAddr = '0x19ee8a65a26f5e4e70b59fdcd8e1047920b57c13';
const cdpManagerAddr = '0xb1fd1f2c83a6cb5155866169d81a9b7cf9e2019d';
const daiJoinAddr = '0x9e0d5a6a836a6c323cf45eb07cb40cfc81664eec';
const getCdpsAddr = '0x05e0690128dcef6e16126e5a4f8f4a226797567d';
const vatAddr = '0xb597803e4b5b2a43a92f3e1dcafea5425c873116';
const jugAddr = '0x9404a7fd173f1aa716416f391accd28bd0d84406';
const spotterAddr = '0x932e82e999fad1f7ea9566f42cd3e94a4f46897e';
const faucetAddr = '0x94598157fcf0715c3bc9b4a35450cce82ac57b20';
const subscriptionsProxyAddr = '0x70A1C12A73f6651B985bC8D24cb22Af55723fd1b';
const subscriptionsAddr = '0x8A03402992dE0057f3cc588002f2fD825CE5971c';
const mcdMonitorAddr = '0xE8531b07418DD1C988C1f76501432E21C27905De';
const mcdMonitorProxyAddr = '0xB77bCacE6Fa6415F40798F9960d395135F4b3cc1';

const exchangeAddr = '0xB14aE674cfa02d9358B0e93440d751fd9Ab2831C';

const mcdSaverProxyAddr = '0x517063901EB05ED58D8F328D98104E4e29F62007';

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
        'ETH': '0x55cd2f4cf74edc7c869bcf5e16086781ee97ee40',
        'BAT': '0xe56b354524115f101798d243e05fd891f7d92e99',
        'GNT': '0xc667ac878fd8eb4412dcad07988fea80008b65ee',
        'OMG': '0x2ebb31f1160c7027987a03482ab0fec130e98251',
        'ZRX': '0x1f4150647b4aa5eb36287d06d757a5247700c521',
        'REP': '0xd40163ea845abbe53a12564395e33fe108f90cd3',
        'DGD': '0xd5f63712af0d62597ad6bf8d357f163bc699e18c',
    },
    '42': {
        'ETH': '0x55cd2f4cf74edc7c869bcf5e16086781ee97ee40',
        'BAT': '0xe56b354524115f101798d243e05fd891f7d92e99',
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

let web3, account, jug, oasisTrade, registry, proxy, join, vat, getCdps, proxyAddr, spotter, mcdSaverProxy, mcdMonitor, mcdMonitorProxy, subscriptions, subscriptionsProxy;

const initContracts = async () => {
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.KOVAN_INFURA_ENDPOINT));

    account = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY)
    web3.eth.accounts.wallet.add(account)

    registry = new web3.eth.Contract(ProxyRegistryInterface.abi, proxyRegistryAddr);

    proxyAddr = await registry.methods.proxies(account.address).call();
    proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);

    join = new web3.eth.Contract(Join.abi, '0x92a3b1c0882e6e17aa41c5116e01b0b9cf117cf2');
    getCdps = new web3.eth.Contract(GetCdps.abi, getCdpsAddr);
    vat = new web3.eth.Contract(Vat.abi, vatAddr);
    jug = new web3.eth.Contract(Jug.abi, jugAddr);
    spotter = new web3.eth.Contract(Spotter.abi, spotterAddr);
    mcdSaverProxy = new web3.eth.Contract(MCDSaverProxy.abi, mcdSaverProxyAddr);
    faucet = new web3.eth.Contract(Faucet.abi, faucetAddr);
    exchange = new web3.eth.Contract(ExchangeInterface.abi, exchangeAddr);

    mcdMonitor = new web3.eth.Contract(MCDMonitor.abi, mcdMonitorAddr);
    mcdMonitorProxy = new web3.eth.Contract(MCDMonitorProxy.abi, mcdMonitorProxyAddr);
    subscriptionsProxy = new web3.eth.Contract(SubscriptionsProxy.abi, subscriptionsProxyAddr);
    subscriptions = new web3.eth.Contract(Subscriptions.abi, subscriptionsAddr);
};

(async () => {
    await initContracts();

    // await openCdp("ETH", "1", "50");

    const usersCdps = await getCDPsForAddress(proxyAddr);
    console.log(usersCdps);

    // await getRatioFromContract(usersCdps[0].cdpId);


    // let minRatio = web3.utils.toWei('6.0', 'ether');
    // let maxRatio = web3.utils.toWei('7.0', 'ether');
    // let optimalRatio = web3.utils.toWei('6.5', 'ether');

    // console.log(usersCdps[0].cdpId, minRatio, maxRatio, optimalRatio, optimalRatio);
    // await subscribeCdp(usersCdps[0].cdpId, minRatio, maxRatio, optimalRatio, optimalRatio);

    // const cdp = await subscriptions.methods.getCdp(usersCdps[0].cdpId).call();
    // console.log("subscribed: ", cdp);

    await boost(usersCdps[0].cdpId, '10');

    // await repayFor(usersCdps[0].cdpId, web3.utils.toWei('0.1', 'ether'), getTokenJoinAddr('ETH'));
    // await boostFor(usersCdps[0].cdpId, web3.utils.toWei('0.4', 'ether'), getTokenJoinAddr('ETH'));

    const cdpInfo = await getCdpInfo(usersCdps[0]);
    console.log("ratio: ", cdpInfo.ratio);
    console.log("cdp: ", cdpInfo);

    // await openCdp('ETH', '2', '100');

    // const cdpInfo2 = await getCdpInfo(usersCdps[1]);
    // console.log(cdpInfo2.ratio, cdpInfo2.collateral /  1e18, cdpInfo2.debtWithFee / 1e18);

    // await transfer(usersCdps[1].cdpId, '0x322d58b9E75a6918f7e7849AEe0fF09369977e08');

    // const res = await getCollateralInfo(getIlk('REP'));

    // console.log(res);

    // await faucet.methods.gulp(getTokenAddr('GNT')).send({from: account.address, gas: 300000});


})();

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

        const cdp = await subscriptions.methods.getCdp(usersCdps[0].cdpId).call();

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
        [cdpManagerAddr, jugAddr, getTokenJoinAddr('DAI'), cdpId, daiAmount]);

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


const boost = async (cdpId, amount) => {
    try {
        const daiAmount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDSaverProxy, 'boost'),
          [cdpId, getTokenJoinAddr('ETH'), daiAmount, 0, 2, 0]);

        const tx = await proxy.methods['execute(address,bytes)'](mcdSaverProxyAddr, data).send({
            from: account.address, gas: 1200000});

        // console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const repay = async (cdpId, amount) => {
    try {
        console.log("Regular repay");
        const ethAmount = web3.utils.toWei(amount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDSaverProxy, 'repay'),
          [cdpId, getTokenJoinAddr('ETH'), ethAmount, 0, 4, 0]);

        const tx = await proxy.methods['execute(address,bytes)'](mcdSaverProxyAddr, data).send({
            from: account.address, gas: 1200000});

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

const getCollateralInfo = async (ilk) => {
    try {
        const ilkInfo = await subscriptions.methods.getIlkInfo(ilk, 0).call();

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
