
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
const proxyActionsAddr = '0xc21274797a01e133ebd9d79b23498edbd7166137';
const cdpManagerAddr = '0x1cb0d969643af4e929b3fafa5ba82950e31316b8';
const ethAJoinAddr = '0xc3abba566bb62c09b7f94704d8dfd9800935d3f9';
const daiJoinAddr = '0x61af28390d0b3e806bbaf09104317cb5d26e215d';
const getCdpsAddr = '0xb5907a51e3b747dbf9d5125ab77eff3a55e50b7d';
const vatAddr = '0x6e6073260e1a77dfaf57d0b92c44265122da8028';
const jugAddr = '0x3793181ebbc1a72cc08ba90087d21c7862783fa5';
const spotterAddr = '0xf5cdfce5a0b85ff06654ef35f4448e74c523c5ac';
const faucetAddr = '0x94598157fcf0715c3bc9b4a35450cce82ac57b20';
const subscriptionsProxyAddr = '0x70A1C12A73f6651B985bC8D24cb22Af55723fd1b';
const subscriptionsAddr = '0x8A03402992dE0057f3cc588002f2fD825CE5971c';
const mcdMonitorAddr = '0xE8531b07418DD1C988C1f76501432E21C27905De';
const mcdMonitorProxyAddr = '0xB77bCacE6Fa6415F40798F9960d395135F4b3cc1';

const exchangeAddr = '0xB14aE674cfa02d9358B0e93440d751fd9Ab2831C';

const batAddr = '0x9f8cfb61d3b2af62864408dd703f9c3beb55dff7';

const mcdSaverProxyAddr = '0x98D2fEDe8AA4eB5014aC6001eCd0c1AbF0fbF408';

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
        'ETH': '0xc3abba566bb62c09b7f94704d8dfd9800935d3f9',
        'BAT': '0x9f8cfb61d3b2af62864408dd703f9c3beb55dff7',
        'GNT': '0xc81ba844f451d4452a01bbb2104c1c4f89252907',
        'OMG': '0x441b1a74c69ee6e631834b626b29801d42076d38',
        'ZRX': '0x18392097549390502069c17700d21403ea3c721a',
        'REP': '0xc7aa227823789e363f29679f23f7e8f6d9904a9b',
        'DGD': '0x62aeec5fb140bb233b1c5612a8747ca1dc56dc1b',
    },
    '42': {
        'ETH': '0xc3abba566bb62c09b7f94704d8dfd9800935d3f9',
        'BAT': '0xf8e9b4c3e17c1a2d55767d44fb91feed798bb7e8',
        'GNT': '0xc28d56522280d20c1c33b239a8e8ffef1c2d5457',
        'OMG': '0x7d9f9e9ac1c768be3f9c241ad9420e9ac37688e4',
        'ZRX': '0x79f15b0da982a99b7bcf602c8f384c56f0b0e8cd',
        'REP': '0xebbd300bb527f1d50abd937f8ca11d7fd0e5b68b',
        'DGD': '0x92a3b1c0882e6e17aa41c5116e01b0b9cf117cf2',
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

    // await repay(usersCdps[0].cdpId, '0.05');

    // await repayFor(usersCdps[0].cdpId, web3.utils.toWei('0.1', 'ether'), getTokenJoinAddr('ETH'));
    // await boostFor(usersCdps[0].cdpId, web3.utils.toWei('0.4', 'ether'), getTokenJoinAddr('ETH'));

    // const cdpInfo = await getCdpInfo(usersCdps[0]);


    const info1 = await getCollateralInfo(usersCdps[0].ilk);
    const info2 = await getCollateralInfo2(usersCdps[0].cdpId);
    console.log("info1: ", info1);
    console.log("info2: ", info2);

    //  await swap();

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
