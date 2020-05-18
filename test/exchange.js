let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent, balance, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const Dec = require('decimal.js');

const { getBalance, approve, loadAccounts, getAccounts, getProxy, fetchMakerAddresses, saverExchangeAddress, ETH_ADDRESS, nullAddress } = require('./helper.js');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const SaverExchange = contract.fromArtifact('SaverExchange');

const makerVersion = "1.0.6";

describe("Exchange", accounts => {
    let registry, proxy, proxyAddr, makerAddresses, exchange, web3Exchange;

    before(async () => {
    	makerAddresses = await fetchMakerAddresses(makerVersion);

        web3 = loadAccounts(web3);
        accounts = getAccounts(web3);

        registry = await ProxyRegistryInterface.at(makerAddresses["PROXY_REGISTRY"]);

        const proxyInfo = await getProxy(registry, accounts[0]);
        proxy = proxyInfo.proxy;
        proxyAddr = proxyInfo.proxyAddr;
        web3Proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);

        exchange = await SaverExchange.at(saverExchangeAddress);
        web3Exchange = new web3.eth.Contract(SaverExchange.abi, saverExchangeAddress);
    });


    // it('... should sell Ether for Dai', async () => {
    //     const value = web3.utils.toWei('10', 'ether');

    //     const daiBalanceBefore = await getBalance(web3, accounts[0], makerAddresses["MCD_DAI"]);

    //     await web3Exchange.methods.sell(
    //         [ETH_ADDRESS, makerAddresses["MCD_DAI"], value, 0, 0, 0, nullAddress, "0x0", 0]).send({from: accounts[0], value, gas: 3000000});

    //     const daiBalanceAfter = await getBalance(web3, accounts[0], makerAddresses["MCD_DAI"]);

    //     expect(daiBalanceAfter).to.be.bignumber.is.above(daiBalanceBefore);
    // });

    it('... should sell Dai for Ether', async () => {
        const value = web3.utils.toWei('100', 'ether');

        await approve(web3, makerAddresses["MCD_DAI"], accounts[0], saverExchangeAddress);

        console.log(makerAddresses["MCD_DAI"]);

        const etherBalanceBefore = await getBalance(web3, accounts[0], ETH_ADDRESS);
        console.log(etherBalanceBefore/1e18);

        await web3Exchange.methods.sell(
            [makerAddresses["MCD_DAI"], ETH_ADDRESS, value, 0, 0, 1, nullAddress, "0x0", 0]).send({from: accounts[0], value: 0, gas: 5000000});

        const etherBalanceAfter = await getBalance(web3, accounts[0], ETH_ADDRESS);

        console.log(etherBalanceAfter/1e18);
        expect(etherBalanceAfter).to.be.bignumber.is.above(etherBalanceBefore);
    });

});
