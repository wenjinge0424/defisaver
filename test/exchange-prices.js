let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent, balance, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const Dec = require('decimal.js');

const { wdiv, wmul, getBalance, approve, loadAccounts, getAccounts, getProxy, fetchMakerAddresses, saverExchangeAddress, ETH_ADDRESS, WETH_ADDRESS, nullAddress, transferToken, MAX_UINT } = require('./helper.js');

const Prices = contract.fromArtifact("Prices");

const pricesAddress = '0x9a355c00d7f5ad0c702e512f2ba9abfdaae6845d';

const uniswapWrapperAddr = '0x91f92970A201F507734E61a7100C8fc2f2EAF495';
const kyberWrapperAddr = '0xeEA6F50596e50696e9B2ed04581BaAA608A97BF8';
const uniswapV2WrapperAddr = '0x25Cd147d46E17be2eC03C90D079c2bE840cC02A6';
const oasisTradeWrapperAddr = '0xE89C8fE2259DaB9894068Bd57eF43eab229F9dfd';

const usdc = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
const usdt = '0xdac17f958d2ee523a2206206994597c13d831ec7';
const dai = '0x6b175474e89094c44da98b954eedeac495271d0f';
const wbtc = '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599';

const sellToken = ETH_ADDRESS; //usdc;
const buyToken = usdc; //ETH_ADDRESS;
const value = '100000000'; // '1000000000000000000';//'1000000'; // '1000000'; //

describe("ExchangePrices", accounts => {
    let prices;

    before(async () => {
        web3 = loadAccounts(web3);
        accounts = getAccounts(web3);

        prices = new web3.eth.Contract(Prices.abi, pricesAddress);
    });

    it('... should check sell prices', async () => {
        const ethAmount = web3.utils.toWei('1');
        console.log(`Selling ${ethAmount} eth`);

        const sellRateUni = await prices.methods.getExpectedRate(
            uniswapWrapperAddr, sellToken, buyToken,  ethAmount, 0).call();

        console.log('UNI V1: ', sellRateUni);

        const sellRateUni2 = await prices.methods.getExpectedRate(
            uniswapV2WrapperAddr, sellToken, buyToken,  ethAmount, 0).call();

        console.log('UNI V2: ', sellRateUni2);

        const sellRateKyber = await prices.methods.getExpectedRate(
            kyberWrapperAddr, sellToken, buyToken,  ethAmount, 0).call();

        console.log('Kyber: ', sellRateKyber);

        const sellRateOasis = await prices.methods.getExpectedRate(
            oasisTradeWrapperAddr, sellToken, buyToken,  ethAmount, 0).call();

        console.log('Oasis: ', sellRateOasis);
    });


    it('... should check buy prices', async () => {
        const daiAmount = '103000000'; //web3.utils.toWei('103');
        console.log(`Buying ${daiAmount} dai`);

        const buyRateUni = await prices.methods.getExpectedRate(
            uniswapWrapperAddr, sellToken, buyToken,  daiAmount, 1).call();

        console.log('UNI V1: ', buyRateUni);

        const buyRateUni2 = await prices.methods.getExpectedRate(
            uniswapV2WrapperAddr, sellToken, buyToken,  daiAmount, 1).call();

        console.log('UNI V2: ', buyRateUni2);

        const buyRateKyber = await prices.methods.getExpectedRate(
            kyberWrapperAddr, sellToken, buyToken,  daiAmount, 1).call();

        console.log('Kyber: ', buyRateKyber);

        const buyRateOasis = await prices.methods.getExpectedRate(
            oasisTradeWrapperAddr, sellToken, buyToken,  daiAmount, 1).call();

        console.log('Oasis: ', buyRateOasis);
    });


    // it('... should check Kyber get best buy price logic', async () => {
    //     const amount =  web3.utils.toWei('103'); 
    //     console.log(`Buying ${amount} dai`);

    //     const sellRate = await prices.methods.getExpectedRate(
    //         kyberWrapperAddr, buyToken, sellToken, amount, 0).call();

    //     const sellAmount = wmul(amount, sellRate).toFixed(0);
    //     console.log({sellAmount});

    //     const finalRate = await prices.methods.getExpectedRate(
    //         kyberWrapperAddr, sellToken, buyToken, sellAmount, 0).call();        

    //     console.log({finalRate});
    //     console.log(wmul(sellAmount, finalRate));
    // });


    // it('... should check Oasis rates', async () => {
    //     const sellRate = await prices.methods.getBestPrice(value, sellToken, buyToken,  1, 0).call();
    //     const amountToBuy = wmul(value, sellRate['1']);
    //     console.log(sellRate['1']);
    //     console.log(amountToBuy.toFixed(0))

    //     const buyRate = await prices.methods.getBestPrice(amountToBuy.toFixed(0), sellToken, buyToken, 1, 1).call();
    //     const amountToPay = wdiv(value, buyRate['1']);
    //     console.log(buyRate['1']);
    //     console.log(amountToPay.toFixed(0));
    // });

    // it('... should Kyber rates', async () => {
    //     const sellRate = await prices.methods.getBestPrice(value, sellToken, buyToken,  2, 0).call();
    //     const amountToBuy = wmul(value, sellRate['1']);
    //     console.log(sellRate['1']);
    //     console.log(amountToBuy.toFixed(0))

    //     const buyRate = await prices.methods.getBestPrice(amountToBuy.toFixed(0), sellToken, buyToken, 2, 1).call();
    //     const amountToPay = wdiv(value, buyRate['1']);
    //     console.log(buyRate['1']);
    //     console.log(amountToPay.toFixed(0));
    // });

    // it('... should Uniswap rates', async () => {
    //     const sellRate = await prices.methods.getBestPrice(value, sellToken, buyToken,  3, 0).call();
    //     const amountToBuy = wmul(value, sellRate['1']);
    //     console.log(sellRate['1']);
    //     console.log(amountToBuy.toFixed(0))

    //     const buyRate = await prices.methods.getBestPrice(amountToBuy.toFixed(0), sellToken, buyToken, 3, 1).call();
    //     const amountToPay = wdiv(value, buyRate['1']);
    //     console.log(buyRate['1']);
    //     console.log(amountToPay.toFixed(0));
    // });

});
