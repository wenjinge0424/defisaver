let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent, balance, BN } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const { getAbiFunction, loadAccounts, getAccounts, getProxy, fetchMakerAddresses, saverExchangeAddress, ETH_ADDRESS, nullAddress, mcdSaverProxyAddress } = require('./helper.js');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const ERC20 = contract.fromArtifact("ERC20");
const Join = contract.fromArtifact("Join");
const GetCdps = contract.fromArtifact('GetCdps');
const DSSProxyActions = contract.fromArtifact('DssProxyActions');
const MCDSaverProxy = contract.fromArtifact('MCDSaverProxy');
const SaverExchange = contract.fromArtifact('SaverExchange');

const makerVersion = "1.0.6";

describe("MCDBasic", accounts => {
    let registry, proxy, join, getCdps, proxyAddr, ethJoin, wbtcJoin, makerAddresses, exchange, web3Exchange, saverProxy;

    before(async () => {
    	makerAddresses = await fetchMakerAddresses(makerVersion);

        web3 = loadAccounts(web3);
        accounts = getAccounts(web3);

        registry = await ProxyRegistryInterface.at(makerAddresses["PROXY_REGISTRY"]);

        const proxyInfo = await getProxy(registry, accounts[0]);
        proxy = proxyInfo.proxy;
        proxyAddr = proxyInfo.proxyAddr;

        getCdps = await GetCdps.at(makerAddresses["GET_CDPS"]);
        ethJoin = await Join.at(makerAddresses["MCD_JOIN_ETH_A"]);
        wbtcJoin = await Join.at(makerAddresses["MCD_JOIN_WBTC_A"]);
        batJoin = await Join.at(makerAddresses["MCD_JOIN_BAT_A"])
        usdcJoin = await Join.at(makerAddresses["MCD_JOIN_USDC_A"])
        mcdSaverProxy = await MCDSaverProxy.at(mcdSaverProxyAddress);

        exchange = await SaverExchange.at(saverExchangeAddress);
        web3Exchange = new web3.eth.Contract(SaverExchange.abi, saverExchangeAddress);
    });

    it('...get ethJoin ilk', async () => {

        const ilk = await ethJoin.ilk();
    });

    it('... reads all the CDPs', async () => {
        const cdps = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);
    });

    it('... should be able to open ETH CDP', async () => {
    	const ethIlk = await ethJoin.ilk();
        const value = web3.utils.toWei('10', 'ether');
        const daiAmount = web3.utils.toWei('100', 'ether');

    	const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'openLockETHAndDraw'),
         [makerAddresses['CDP_MANAGER'], makerAddresses['MCD_JUG'], makerAddresses["MCD_JOIN_ETH_A"], makerAddresses["MCD_JOIN_DAI"], ethIlk, daiAmount]);

    	const cdpsBefore = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

    	const receipt = await proxy.methods['execute(address,bytes)'](makerAddresses['PROXY_ACTIONS'], data, {
            from: accounts[0], value});

    	const cdpsAfter = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

    	expect(cdpsAfter.ids.length).to.equal(cdpsBefore.ids.length+1);
    });

    it('... should be able to buy WBTC', async () => {
        const value = web3.utils.toWei('10', 'ether');
        const bal = await web3.eth.getBalance(accounts[0]);
        const weiBal = web3.utils.fromWei(bal.toString(), 'ether')

        await web3Exchange.methods.swapTokenToToken(ETH_ADDRESS, makerAddresses["WBTC"], value, 0, 0, nullAddress, "0x0", 0).send({from: accounts[0], value, gas: 3000000});

        const newBal = await web3.eth.getBalance(accounts[0]);
        const newWeiBal = web3.utils.fromWei(newBal.toString(), 'ether')

        // include gasCost in expectation
        expect(parseFloat(weiBal)).to.be.within(parseFloat(newWeiBal) + 10, parseFloat(newWeiBal) + 10.2);
    });

    it('... should be able to open WBTC CDP with all wbtc balance', async () => {
        const wbtcIlk = await wbtcJoin.ilk();
        const daiAmount = web3.utils.toWei('50', 'ether');

        const wbtcToken = await ERC20.at(makerAddresses["WBTC"]);
        
        const wbtcAmount = await wbtcToken.balanceOf(accounts[0]);

        await wbtcToken.approve(proxyAddr, wbtcAmount.toString(), {from: accounts[0]});

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'openLockGemAndDraw'),
         [makerAddresses['CDP_MANAGER'], makerAddresses['MCD_JUG'], makerAddresses["MCD_JOIN_WBTC_A"], makerAddresses["MCD_JOIN_DAI"], wbtcIlk, wbtcAmount.toString(), daiAmount, true]);

        const cdpsBefore = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

        await proxy.methods['execute(address,bytes)'](makerAddresses['PROXY_ACTIONS'], data, {from: accounts[0]});

        const cdpsAfter = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

        expect(cdpsAfter.ids.length).to.equal(cdpsBefore.ids.length+1);
    });

    it('... should be able to boost WBTC CDP', async () => {
        const wbtcIlk = await wbtcJoin.ilk();
        // 10 dai
        const daiAmount = web3.utils.toWei('15', 'ether');

        const cdps = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

        // last made is wbtc cdp
        const cdpId = cdps.ids[cdps.ids.length-1];

        const infoBefore = await mcdSaverProxy.getCdpDetailedInfo(cdpId.toString());

        const uintData = [cdpId.toString(), daiAmount, '0', '0', '0', '0'];
        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDSaverProxy, 'boost'),
         [uintData, makerAddresses["MCD_JOIN_WBTC_A"], nullAddress, '0x0']);

        const tx = await proxy.methods['execute(address,bytes)'](mcdSaverProxyAddress, data, {from: accounts[0]});

        const infoAfter = await mcdSaverProxy.getCdpDetailedInfo(cdpId.toString());

        const debtBn = new BN(infoAfter.debt.toString());
        const daiBn = new BN(daiAmount);
        const daiAmountBn = debtBn.add(daiBn);
        const offset = new BN(web3.utils.toWei('0.0001', 'ether'));

        // because of stability fee
        expect(infoBefore.debt).to.be.within(daiAmountBn, daiAmountBn.add(offset));
    });

    it('... should be able to repay WBTC CDP', async () => {
        const wbtcIlk = await wbtcJoin.ilk();
        // 0.001 wbtc == close to 10 dai
        const wbtcAmount = new BN(web3.utils.toWei('0.001', 'ether'));
        const divider = new BN(1e10);
        const wbtcAmountNormalize = wbtcAmount.div(divider);
        
        const cdps = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

        // last made is wbtc cdp
        const cdpId = cdps.ids[cdps.ids.length-1];

        const infoBefore = await mcdSaverProxy.getCdpDetailedInfo(cdpId.toString());

        const uintData = [cdpId.toString(), wbtcAmountNormalize.toString(), '0', '0', '0', '0'];

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MCDSaverProxy, 'repay'),
         [uintData, makerAddresses["MCD_JOIN_WBTC_A"], nullAddress, '0x0']);

        const tx = await proxy.methods['execute(address,bytes)'](mcdSaverProxyAddress, data, {from: accounts[0]});

        const infoAfter = await mcdSaverProxy.getCdpDetailedInfo(cdpId.toString());

        const collateralBn = new BN(infoAfter.collateral.toString())
        const wbtcAmountBn = collateralBn.add(wbtcAmount);

        const collateralBefore = new BN(infoBefore.collateral.toString())

        const ratioBefore = await mcdSaverProxy.getRatio(cdpId.toString(), wbtcIlk);

        expect(collateralBefore.toString()).to.be.equal(wbtcAmountBn.toString());
    });
});
