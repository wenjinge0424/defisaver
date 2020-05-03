let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent, balance } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const { getAbiFunction, loadAccounts, getAccounts, getProxy, fetchMakerAddresses } = require('./helper.js');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const ERC20 = contract.fromArtifact("ERC20");
const Join = contract.fromArtifact("Join");
const GetCdps = contract.fromArtifact('GetCdps');
const DSSProxyActions = contract.fromArtifact('DssProxyActions');

const makerVersion = "1.0.6";

describe("MCDBasic", accounts => {
    let registry, proxy, join, getCdps, proxyAddr, ethJoin, wbtcJoin, makerAddresses;

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

        const balanceEth = await balance.current(accounts[0], 'ether')
        console.log("Acc balance: ", balanceEth.toString());

    });

    it('...get info', async () => {

        const ilk = await ethJoin.ilk();

        console.log(ilk.toString());
    });

    it('... reads all the CDPs', async () => {
        const cdps = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

        console.log(cdps);
    });

    it('... should be able to open ETH CDP', async () => {
    	const ethIlk = await ethJoin.ilk();

    	const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'open'),
         [makerAddresses['CDP_MANAGER'], ethIlk, proxyAddr]);

    	const cdpsBefore = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

    	const receipt = await proxy.execute(makerAddresses['PROXY_ACTIONS'], data, {
            from: accounts[0]});

    	const cdpsAfter = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);

    	console.log(receipt);
    	console.log(cdpsBefore.ids.length);
    	console.log(cdpsAfter.ids.length);

    	expect(cdpsAfter.ids.length).to.equal(cdpsBefore.ids.length+1);
    });
});
