
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

const batAddr = '0x9f8cfb61d3b2af62864408dd703f9c3beb55dff7';

const mcdSaverProxyAddr = '0xa054E265dc4c62a75f3244d5ddFA6b22A07E6597';

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
        'BAT': '0x9f8cfb61d3b2af62864408dd703f9c3beb55dff7',
        'GNT': '0xc81ba844f451d4452a01bbb2104c1c4f89252907',
        'OMG': '0x441b1a74c69ee6e631834b626b29801d42076d38',
        'ZRX': '0x18392097549390502069c17700d21403ea3c721a',
        'REP': '0xc7aa227823789e363f29679f23f7e8f6d9904a9b',
        'DGD': '0x62aeec5fb140bb233b1c5612a8747ca1dc56dc1b',
    },
    '42': {
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

let web3, account, jug, registry, proxy, join, vat, getCdps, proxyAddr, spotter, mcdSaverProxy;

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
};

(async () => {
    await initContracts();

    // const usersCdps = await getCDPsForAddress(proxyAddr);


    // await addCollateral(usersCdps[0].cdpId);
    // await boost(usersCdps[0].cdpId);

    // await faucet.methods.gulp(getTokenAddr('GNT')).send({from: account.address, gas: 300000});

    // const ilkInfo = await getCollateralInfo(ethIlk);
    // console.log(ilkInfo);

    // const cdpInfo = await getCdpInfo(ilkInfo, usersCdps[0]);
    // console.log(cdpInfo);

})();

const addCollateral = async (cdpId) => {
    try {
        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'lockETH'),
          [cdpManagerAddr, ethAJoinAddr, cdpId]);

          const ethAmount = web3.utils.toWei('0.1', 'ether');

          const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({from: account.address, value: ethAmount, gas: 900000});

          console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const addAndDraw = async (cdpId) => {
    try {
        const daiAmount = web3.utils.toWei('1', 'ether');
        const ethAmount = web3.utils.toWei('0.1', 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'lockETHAndDraw'),
          [cdpManagerAddr, jugAddr, ethAJoinAddr, daiJoinAddr, cdpId, daiAmount]);

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({
            from: account.address, gas: 900000, value: ethAmount});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const drawDai = async (cdpId) => {
    try {
        const daiAmount = web3.utils.toWei('1', 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'draw'),
          [cdpManagerAddr, jugAddr, daiJoinAddr, cdpId, daiAmount]);

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({
            from: account.address, gas: 900000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

// address manager,
//         address jug,
//         address gemJoin,
//         address daiJoin,
//         bytes32 ilk,
//         uint wadC,
//         uint wadD,
//         bool transferFrom
const openCdp = async (type, collateralAmount, daiAmount) => {
    try {
        daiAmount = web3.utils.toWei('0.1', 'ether');
        collateralAmount = web3.utils.toWei('10', 'ether'); //TODO: to collateral precision

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'openLockGemAndDraw'),
          [cdpManagerAddr, jugAddr, getTokenJoinAddr(type), daiJoinAddr, getIlk(type), collateralAmount, daiAmount, true]);

        const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data).send({
            from: account.address, gas: 900000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const getCollateralInfo = async (ilk) => {
    try {
        const ilkInfo = await vat.methods.ilks(ilk).call();

        const spotInfo = await spotter.methods.ilks(ilk).call();

        return {
            currentRate: ilkInfo.rate,
            price: ilkInfo.spot, // TODO: check if true
            minAmountForCdp: ilkInfo.dust,
            currAmountGlobal: ilkInfo.Art, //total debt TODO: * rate
            maxAmountGlobal: ilkInfo.line,
            liquidationRatio: spotInfo.mat,
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

const boost = async (cdpId) => {
    try {
        const daiAmount = web3.utils.toWei('1', 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDSaverProxy, 'boost'),
          [cdpId, daiAmount, 0, 0]);

        const tx = await proxy.methods['execute(address,bytes)'](mcdSaverProxyAddr, data).send({
            from: account.address, gas: 900000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};

const getCdpInfo = async (ilkInfo, cdp) => {
    try {
        const urn = await vat.methods.urns(cdp.ilk, cdp.urn).call();

        const collateral = Dec(urn.ink);
        const debt = Dec(urn.art);

        const debtWithFee = debt.times(ilkInfo.currentRate).div(1e27);
        const stabilityFee = debtWithFee.sub(debt);

        const price = Dec(ilkInfo.price).div(1e27);
        const ratio = collateral.times(price).div(debtWithFee).times(100);

        const liquidationPrice = debt.times(ilkInfo.liquidationRatio).div(collateral).div(1e27);

        return {
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


    // it('...get info', async () => {

    //     console.log(join.methods);
    //     const ilk = await join.ilk.call();

    //     console.log(ilk.toString());
    // });
