let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent } = require('@openzeppelin/test-helpers');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const AaveBasicProxy = contract.fromArtifact("AaveBasicProxy");
const ERC20 = contract.fromArtifact("ERC20");
const AaveImportTaker = contract.fromArtifact("AaveImportTaker");

const { expect } = require('chai');

const { getAbiFunction, loadAccounts, getAccounts, getProxy, getBalance, approve, fetchMakerAddresses, transferToken } = require('./helper.js');

const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const AETH_ADDRESS = '0x3a3a65aab0dd2a17e3f1947ba16138cd37d08c04';
const ADAI_ADDRESS = '0xfc1e690f61efd961294b3e1ce3313fbd8aa4f85d';

const aaveBasicProxyAddr = "0x59d3631c86BbE35EF041872d502F218A39FBa150";
const aaveImportTakerAddr = "0xCeeFD27e0542aFA926B87d23936c79c276A48277";

const makerVersion = "1.0.6";

describe("AaveImport", () => {

    let registry, proxy, proxyAddr, aaveBasicProxy, makerAddresses;

    let accounts;

    before(async () => {

        web3 = loadAccounts(web3);
        accounts = getAccounts(web3);
        makerAddresses = await fetchMakerAddresses(makerVersion);

        registry = await ProxyRegistryInterface.at("0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4");
        // aaveBasicProxy = await AaveBasicProxy.at(aaveBasicProxyAddr);
        aaveImportTaker = new web3.eth.Contract(AaveImportTaker.abi, aaveImportTakerAddr);

        const proxyInfo = await getProxy(registry, accounts[0]);
        proxy = proxyInfo.proxy;
        proxyAddr = proxyInfo.proxyAddr;
    });

    it('...should do something', async () => {

        await aaveImportTaker.methods.importLoan(ETH_ADDRESS, ETH_ADDRESS, web3.utils.toWei('10')).send({from: accounts[0], gas: 4000000, value: '2'});
    });

});
