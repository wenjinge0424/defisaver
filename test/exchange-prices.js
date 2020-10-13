let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent, balance, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const Dec = require('decimal.js');
Dec.set({
  rounding: Dec.ROUND_DOWN,
  precision: 40,
  toExpPos: 9e15,
  toExpNeg: -9e15,
});

const { wdiv, wmul, getBalance, approve, loadAccounts, getAccounts, getProxy, fetchMakerAddresses, saverExchangeAddress, ETH_ADDRESS, WETH_ADDRESS, nullAddress, transferToken, MAX_UINT, getDecimals } = require('./helper.js');

const Prices = contract.fromArtifact("Prices");

const pricesAddress = '0x9a355c00d7f5ad0c702e512f2ba9abfdaae6845d';

const uniswapWrapperAddr = '0x14af8Af6dccFF858AB465f13506cB7b3561C024E';
const kyberWrapperAddr = '0x84C00C34e07eEDF2095E48e2a17d97F2449bC867';
const uniswapV2WrapperAddr = '0x14af8Af6dccFF858AB465f13506cB7b3561C024E';
const oasisTradeWrapperAddr = '0x3Ba0319533C578527aE69BF7fA2D289F20B9B55c';


const getName = (addr) => {
    switch(addr) {
      case "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48":
        return 'usdc';
      case "0xdac17f958d2ee523a2206206994597c13d831ec7":
        return 'usdt';
      case "0x6b175474e89094c44da98b954eedeac495271d0f":
        return 'dai';
      case "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599":
        return 'wbtc';
      default:
        return 'eth';
    } 
}

const usdc = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
const usdt = '0xdac17f958d2ee523a2206206994597c13d831ec7';
const dai = '0x6b175474e89094c44da98b954eedeac495271d0f';
const wbtc = '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599';

const sellToken = wbtc; //usdc;
const buyToken = usdc; //ETH_ADDRESS;
let sellDecimals, buyDecimals, sellTokenDivider, buyTokenDivider;



describe("ExchangePrices", accounts => {
    let prices;

    before(async () => {
        web3 = loadAccounts(web3);
        accounts = getAccounts(web3);

        sellDecimals = await getDecimals(web3, sellToken);
        buyDecimals = await getDecimals(web3, buyToken);

        sellTokenDivider = Dec('10').pow(sellDecimals);
        buyTokenDivider = Dec('10').pow(buyDecimals);

        prices = new web3.eth.Contract(Prices.abi, pricesAddress);
    });

    it('... should check sell prices', async () => {
        const ethAmount =  Dec('1').mul(sellTokenDivider).toString();
        console.log(`Selling ${Dec(ethAmount).div(sellTokenDivider)} ${getName(sellToken)}`);
        console.log('--------------------------------------------------------')
        const sellRateUni = (await prices.methods.getBestPrice(
            ethAmount, sellToken, buyToken, 0, [uniswapWrapperAddr]).call())['1'];
        console.log('UNI V1: ', sellRateUni);
        if (Dec(sellRateUni).gt('0')) console.log(`Would get: ${Dec(wmul(sellRateUni, ethAmount)).div(buyTokenDivider).toFixed(2)} ${getName(buyToken)}`)
        console.log('------------------------------')

        const sellRateUni2 = (await prices.methods.getBestPrice(
            ethAmount, sellToken, buyToken, 0, [uniswapV2WrapperAddr]).call())['1'];
        console.log('UNI V2: ', sellRateUni2);
        if (Dec(sellRateUni2).gt('0')) console.log(`Would get: ${Dec(wmul(sellRateUni2, ethAmount)).div(buyTokenDivider).toFixed(2)} ${getName(buyToken)}`)
        console.log('------------------------------')

        // const sellRateKyber = (await prices.methods.getBestPrice(
        //     ethAmount, sellToken, buyToken, 0, [kyberWrapperAddr]).call())['1'];
        // console.log('Kyber: ', sellRateKyber);
        // if (Dec(sellRateKyber).gt('0')) console.log(`Would get: ${Dec(wmul(sellRateKyber, ethAmount)).div(buyTokenDivider).toFixed(2)} ${getName(buyToken)}`)
        // console.log('------------------------------')

        const sellRateOasis = (await prices.methods.getBestPrice(
            ethAmount, sellToken, buyToken, 0, [oasisTradeWrapperAddr]).call())['1'];
        console.log('Oasis: ', sellRateOasis);
        if (Dec(sellRateOasis).gt('0')) console.log(`Would get: ${Dec(wmul(sellRateOasis, ethAmount)).div(buyTokenDivider).toFixed(2)} ${getName(buyToken)}`)
        console.log('------------------------------')
    });


    it('... should check buy prices', async () => {
        const daiAmount = Dec('350').mul(Dec('10').pow(buyDecimals)).toString();
        console.log(`Buying ${Dec(daiAmount).div(buyTokenDivider)} ${getName(buyToken)}`);
        console.log('--------------------------------------------------------')

        const buyRateUni = (await prices.methods.getBestPrice(
            daiAmount, sellToken, buyToken, 1, [uniswapWrapperAddr]).call())['1'];
        console.log('UNI V1: ', buyRateUni);
        if (Dec(buyRateUni).gt('0')) console.log(`Would need: ${Dec(wdiv(daiAmount, buyRateUni)).div(sellTokenDivider).toFixed(2)} ${getName(sellToken)}`)
        console.log('------------------------------')

        const buyRateUni2 = (await prices.methods.getBestPrice(
            daiAmount, sellToken, buyToken, 1, [uniswapV2WrapperAddr]).call())['1'];
        console.log('UNI V2: ', buyRateUni2);
        if (Dec(buyRateUni2).gt('0')) console.log(`Would need: ${Dec(wdiv(daiAmount, buyRateUni2)).div(sellTokenDivider).toFixed(2)} ${getName(sellToken)}`)
        console.log('------------------------------')

        // const buyRateKyber = (await prices.methods.getBestPrice(
        //     daiAmount, sellToken, buyToken, 1, [kyberWrapperAddr]).call())['1'];
        // console.log('Kyber: ', buyRateKyber);
        // if (Dec(buyRateKyber).gt('0')) console.log(`Would need: ${Dec(wdiv(daiAmount, buyRateKyber)).div(sellTokenDivider).toFixed(2)} ${getName(sellToken)}`)
        // console.log('------------------------------')

        const buyRateOasis = (await prices.methods.getBestPrice(
            daiAmount, sellToken, buyToken, 1, [oasisTradeWrapperAddr]).call())['1'];
        console.log('Oasis: ', buyRateOasis);
        if (Dec(buyRateOasis).gt('0')) console.log(`Would need: ${Dec(wdiv(daiAmount, buyRateOasis)).div(sellTokenDivider).toFixed(2)} ${getName(sellToken)}`)
        console.log('------------------------------')
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
