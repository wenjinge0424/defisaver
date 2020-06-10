let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent } = require('@openzeppelin/test-helpers');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const AaveBasicProxy = contract.fromArtifact("AaveBasicProxy");
const AaveSaverProxy = contract.fromArtifact("AaveSaverProxy");
const ERC20 = contract.fromArtifact("ERC20");
const ILendingPool = contract.fromArtifact("ILendingPool");
const IPriceOracleGetterAave = contract.fromArtifact("IPriceOracleGetterAave");

const { expect } = require('chai');

const { getAbiFunction, loadAccounts, getAccounts, getProxy, getBalance, approve, fetchMakerAddresses } = require('./helper.js');

const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const AETH_ADDRESS = '0x3a3a65aab0dd2a17e3f1947ba16138cd37d08c04';
const ADAI_ADDRESS = '0xfc1e690f61efd961294b3e1ce3313fbd8aa4f85d';

const aaveBasicProxyAddr = "0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab";
const aaveSaverProxyAddr = "0xFF6049B87215476aBf744eaA3a476cBAd46fB1cA";

const makerVersion = "1.0.6";

describe("AaveSaver", () => {

    let registry, proxy, proxyAddr, aaveBasicProxy, makerAddresses, web3proxy;

    let accounts;

    before(async () => {

        web3 = loadAccounts(web3);
        accounts = getAccounts(web3);
        makerAddresses = await fetchMakerAddresses(makerVersion);

        registry = await ProxyRegistryInterface.at("0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4");
        aaveBasicProxy = await AaveBasicProxy.at(aaveBasicProxyAddr);
        aaveSaverProxy = new web3.eth.Contract(AaveSaverProxy.abi, aaveSaverProxyAddr);
        lendingPool = new web3.eth.Contract(ILendingPool.abi, "0x398eC7346DcD622eDc5ae82352F02bE94C62d119");
        priceOracle = new web3.eth.Contract(IPriceOracleGetterAave.abi, "0x76B47460d7F7c5222cFb6b6A75615ab10895DDe4")

        const proxyInfo = await getProxy(registry, accounts[0], web3);
        proxy = proxyInfo.proxy;
        proxyAddr = proxyInfo.proxyAddr;
        web3proxy = proxyInfo.web3proxy;
    });

    it('...should be able to get max collateral and max borrow', async () => {
        const accData = await lendingPool.methods.getUserAccountData(proxyAddr).call();

        const maxColl = await aaveSaverProxy.methods.getMaxCollateral(ETH_ADDRESS, proxyAddr).call();
        const maxBorr = await aaveSaverProxy.methods.getMaxBorrow(makerAddresses["MCD_DAI"], proxyAddr).call();

        console.log("Max collateral: ", maxColl.toString());
        console.log("Max borrow: ", maxBorr.toString());
        console.log(accData);
    });
});