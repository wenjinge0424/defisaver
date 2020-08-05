let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent } = require('@openzeppelin/test-helpers');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const AaveBasicProxy = contract.fromArtifact("AaveBasicProxy");
const ERC20 = contract.fromArtifact("ERC20");
const AaveImportTaker = contract.fromArtifact("AaveImportTaker");

const { expect } = require('chai');

const { getAbiFunction, loadAccounts, getAccounts, getProxy, getBalance, approve, fetchMakerAddresses, transferToken, fundIfNeeded } = require('./helper.js');

const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const AETH_ADDRESS = '0x3a3a65aab0dd2a17e3f1947ba16138cd37d08c04';
const ADAI_ADDRESS = '0xfc1e690f61efd961294b3e1ce3313fbd8aa4f85d';
const WETH_ADDRESS = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';

const aaveBasicProxyAddr = "0x2B816BFeD57bD7f36280CAaD292220dCA5004a6a";
const aaveImportTakerAddr = "0xFC628dd79137395F3C9744e33b1c5DE554D94882";
const aaveImportAddr = '0xb09bCc172050fBd4562da8b229Cf3E45Dc3045A6';

const makerVersion = "1.0.6";

describe("AaveImport", () => {

    let registry, proxy, proxyAddr, aaveBasicProxy, makerAddresses;

    let accounts;

    before(async () => {

        web3 = loadAccounts(web3);
        accounts = getAccounts(web3);
        makerAddresses = await fetchMakerAddresses(makerVersion);

        registry = await ProxyRegistryInterface.at("0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4");
        aaveBasicProxy = await AaveBasicProxy.at(aaveBasicProxyAddr);
        aaveImportTaker = new web3.eth.Contract(AaveImportTaker.abi, aaveImportTakerAddr);

        const proxyInfo = await getProxy(registry, accounts[0]);
        proxy = proxyInfo.proxy;
        proxyAddr = proxyInfo.proxyAddr;
    });

    it('...should import loan from acc to proxy', async () => {
        const userEthDeposited = await getBalance(web3, accounts[0], AETH_ADDRESS);
        console.log(userEthDeposited.toString());

        await fundIfNeeded(web3, accounts[0], aaveImportAddr, minBal='0.1', addBal='0.1');

        const wethBalance = await getBalance(web3, aaveImportAddr, WETH_ADDRESS);
        console.log('weth', wethBalance.toString());

        await approve(web3, AETH_ADDRESS, accounts[0], proxyAddr, web3.utils.toWei('100000'));
        console.log('approved');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(AaveImportTaker, 'importLoan'),
          [ETH_ADDRESS, makerAddresses["MCD_DAI"], web3.utils.toWei('10')]);
        await proxy.methods['execute(address,bytes)'](aaveImportTakerAddr, data, {
            from: accounts[0] });

        console.log('imported');

        // get proxy position
        const proxyEthDeposited = await getBalance(web3, accounts[0], AETH_ADDRESS);
        console.log(proxyEthDeposited.toString());
    });

});
