const { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent } = require('@openzeppelin/test-helpers');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const CompoundBasicProxy = contract.fromArtifact("CompoundBasicProxy");

const { expect } = require('chai');

const { getAbiFunction } = require('./helper.js');

const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const CETH_ADDRESS = '0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5';

const compoundBasicProxyAddr = "0x0F1e33A36fA6a33Ea01460F04c6D8F1FAc2186E3";

describe("Compound Basic", () => {

    let registry, proxy, compoundBasicProxy;

    const testAcc = '0x7d6149aD9A573A6E2Ca6eBf7D4897c1B766841B4';

    before(async () => {

        registry = await ProxyRegistryInterface.at("0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4");
        compoundBasicProxy = await CompoundBasicProxy.at(compoundBasicProxyAddr);

        const proxyAddr = await registry.proxies(testAcc);
        proxy = await DSProxy.at(proxyAddr);

    });

    it('...should despoit 1 Eth into Compound through proxy and enter the market', async () => {
        const amount = web3.utils.toWei('1', 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundBasicProxy, 'deposit'),
          [ETH_ADDRESS, CETH_ADDRESS, amount, false]);

        let value = amount;

        const receipt = await proxy.methods['execute(address,bytes)'](compoundBasicProxyAddr, data, {
            from: testAcc, value});

    });


});
