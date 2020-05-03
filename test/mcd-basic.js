let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent, balance } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const { getAbiFunction, loadAccounts, getAccounts, getProxy, fetchMakerAddresses, saverExchangeAddress, ETH_ADDRESS, nullAddress } = require('./helper.js');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const ERC20 = contract.fromArtifact("ERC20");
const Join = contract.fromArtifact("Join");
const GetCdps = contract.fromArtifact('GetCdps');
const DSSProxyActions = contract.fromArtifact('DssProxyActions');
const SaverExchange = contract.fromArtifact('SaverExchange');

const makerVersion = "1.0.6";

describe("MCDBasic", accounts => {
    let registry, proxy, join, getCdps, proxyAddr, ethJoin, wbtcJoin, makerAddresses, exchange;

    before(async () => {
    	console.log("1");
    	makerAddresses = await fetchMakerAddresses(makerVersion);

    	console.log("2");
        web3 = loadAccounts(web3);
        console.log("3");
        accounts = getAccounts(web3);

        console.log("4");
        registry = await ProxyRegistryInterface.at(makerAddresses["PROXY_REGISTRY"]);

        console.log("5");
        const proxyInfo = await getProxy(registry, accounts[0]);
        proxy = proxyInfo.proxy;
        proxyAddr = proxyInfo.proxyAddr;
        console.log("6");

        getCdps = await GetCdps.at(makerAddresses["GET_CDPS"]);
        ethJoin = await Join.at(makerAddresses["MCD_JOIN_ETH_A"]);
        wbtcJoin = await Join.at(makerAddresses["MCD_JOIN_WBTC_A"]);
        batJoin = await Join.at(makerAddresses["MCD_JOIN_BAT_A"])
        usdcJoin = await Join.at(makerAddresses["MCD_JOIN_USDC_A"])
        console.log("7");

        exchange = await SaverExchange.at(saverExchangeAddress);

        console.log("8");

        const bal = await web3.eth.getBalance(accounts[0]);
        console.log('Acc balance: ', web3.utils.fromWei(bal.toString(), 'ether'));
    });

    it('...get ethJoin ilk', async () => {

        const ilk = await ethJoin.ilk();
    });

    it('... reads all the CDPs', async () => {
        const cdps = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

        console.log(cdps.ilks)
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
        const value = web3.utils.toWei('5', 'ether');
        const bal = await web3.eth.getBalance(accounts[0]);
        const weiBal = web3.utils.fromWei(bal.toString(), 'ether')


        const web3Exchange = new web3.eth.Contract(SaverExchange.abi, saverExchangeAddress);

        await web3Exchange.methods.swapTokenToToken(ETH_ADDRESS, makerAddresses["WBTC"], value, 0, 0, nullAddress, "0x0", 0).send({from: accounts[0], value, gas: 3000000});

        // await exchange.swapTokenToToken(ETH_ADDRESS, makerAddresses["WBTC"], value, 0, 0, nullAddress, "0x0", 0, {from: accounts[0], value, gas: 3000000});

        const newBal = await web3.eth.getBalance(accounts[0]);
        const newWeiBal = web3.utils.fromWei(newBal.toString(), 'ether')

        // include gasCost in expectation
        expect(parseFloat(weiBal)).to.be.within(parseFloat(newWeiBal) + 5, parseFloat(newWeiBal) + 5.2);
    });

    it('... should be able to open WBTC CDP with all wbtc balance', async () => {
        const wbtcIlk = await wbtcJoin.ilk();
        const daiAmount = web3.utils.toWei('10', 'ether');

        const wbtcToken = await ERC20.at(makerAddresses["WBTC"]);
        
        const wbtcAmount = await wbtcToken.balanceOf(accounts[0]);
        await wbtcToken.approve(proxyAddr, wbtcAmount.toString()+"0000000000", {from: accounts[0]});

        console.log('token approved for balance: ', wbtcAmount.toString())

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'openLockGemAndDraw'),
         [makerAddresses['CDP_MANAGER'], makerAddresses['MCD_JUG'], makerAddresses["MCD_JOIN_WBTC_A"], makerAddresses["MCD_JOIN_DAI"], wbtcIlk, wbtcAmount.toString()+"0000000000", daiAmount, true]);

        const cdpsBefore = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

        console.log('Sending tx');

        const web3Proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);

        await web3Proxy.methods['execute(address,bytes)'](makerAddresses['PROXY_ACTIONS'], data).send({from: accounts[0], gas: 5000000});

        const cdpsAfter = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

        expect(cdpsAfter.ids.length).to.equal(cdpsBefore.ids.length+1);
    });
});
