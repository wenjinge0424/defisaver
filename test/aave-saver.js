let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent } = require('@openzeppelin/test-helpers');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const AaveBasicProxy = contract.fromArtifact("AaveBasicProxy");
const AaveSaverProxy = contract.fromArtifact("AaveSaverProxy");
const AaveSaverTaker = contract.fromArtifact("AaveSaverTaker");
const ERC20 = contract.fromArtifact("ERC20");
const ILendingPool = contract.fromArtifact("ILendingPool");
const IPriceOracleGetterAave = contract.fromArtifact("IPriceOracleGetterAave");

const { expect } = require('chai');

const { getAbiFunction, loadAccounts, getAccounts, getProxy, getBalance, approve, fetchMakerAddresses, fundIfNeeded, nullAddress } = require('./helper.js');

const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const AETH_ADDRESS = '0x3a3a65aab0dd2a17e3f1947ba16138cd37d08c04';
const ADAI_ADDRESS = '0xfc1e690f61efd961294b3e1ce3313fbd8aa4f85d';

const aaveBasicProxyAddr = "0xFEd96F5b99A888Cf2567e8da6D33E112f1BD9A14";
const aaveSaverProxyAddr = "0x87358D288C8b7183bF5Ebc7cf9eE7014Df876c10";
const aaveSaverReceiverAddr = "0x482Af2AcA80BFF9BFa9a0d1d958bBCC4A7f0586e";
const aaveSaverTakerAddr = "0xab8962207218415A3dc10A0fa408D98Fd74C46a2";

const uniswapWrapperAddr = '0x14af8Af6dccFF858AB465f13506cB7b3561C024E';

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
        aaveSaverProxy = new web3.eth.Contract(AaveSaverTaker.abi, aaveSaverTakerAddr);
        lendingPool = new web3.eth.Contract(ILendingPool.abi, "0x398eC7346DcD622eDc5ae82352F02bE94C62d119");
        priceOracle = new web3.eth.Contract(IPriceOracleGetterAave.abi, "0x76B47460d7F7c5222cFb6b6A75615ab10895DDe4")

        await fundIfNeeded(web3, accounts[0], aaveSaverReceiverAddr, '0.0000001', '0.000001');

        const proxyInfo = await getProxy(registry, accounts[0], web3);
        proxy = proxyInfo.proxy;
        proxyAddr = proxyInfo.proxyAddr;
        web3proxy = proxyInfo.web3proxy;
    });

    it('...should be able to fetch users position', async () => {
        const position = await lendingPool.methods.getUserAccountData(proxyAddr).call();

        console.log("Starting: ", position.totalBorrowsETH);
    });

    it('...should be able to deposit and boost dai to eth', async () => {
        const amount = web3.utils.toWei('2', 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(AaveBasicProxy, 'deposit'),
          [ETH_ADDRESS, amount]);

        let value = amount;

        const receipt = await proxy.methods['execute(address,bytes)'](aaveBasicProxyAddr, data, {
            from: accounts[0], value});

        const exchangeData = [makerAddresses["MCD_DAI"], ETH_ADDRESS, web3.utils.toWei('500', 'ether'), '0', '0', uniswapWrapperAddr, nullAddress, '0x00', '0'];
        const gasCost = 0;
        const boostData = web3.eth.abi.encodeFunctionCall(getAbiFunction(AaveSaverProxy, 'boost'),
          [exchangeData, gasCost]);        

        const boostReceipt = await proxy.methods['execute(address,bytes)'](aaveSaverProxyAddr, boostData, {
            from: accounts[0], gas: 6000000});
    });

    it('...should be able to fetch users position', async () => {
        const position = await lendingPool.methods.getUserAccountData(proxyAddr).call();
        console.log("After boost: ", position.totalBorrowsETH);
    });

    it('...should be able to repay eth to dai', async () => {
        const amount = web3.utils.toWei('0.3', 'ether');

        const exchangeData = [ETH_ADDRESS, makerAddresses["MCD_DAI"], amount, '0', '0', uniswapWrapperAddr, nullAddress, '0x00', '0'];
        const gasCost = 0;
        const repayData = web3.eth.abi.encodeFunctionCall(getAbiFunction(AaveSaverProxy, 'repay'),
          [exchangeData, gasCost]);        

        const repayReceipt = await proxy.methods['execute(address,bytes)'](aaveSaverProxyAddr, repayData, {
            from: accounts[0], gas: 6000000});
    });

    it('...should be able to fetch users position', async () => {
        const position = await lendingPool.methods.getUserAccountData(proxyAddr).call();
        console.log("After repay:", position.totalBorrowsETH);
    });
});
