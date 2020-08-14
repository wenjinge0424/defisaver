let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent, balance, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const Dec = require('decimal.js');

const {
    getAbiFunction,
    getBalance,
    approve,
    loadAccounts,
    getAccounts,
    getProxy,
    fetchMakerAddresses,
    ETH_ADDRESS,
    ETH_JOIN_ADDRESS,
    BAT_ADDRESS,
    nullAddress,
} = require('./helper.js');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");

const GetCdps = contract.fromArtifact('GetCdps');
const ExchangeInterface = contract.fromArtifact('ExchangeInterface');
const DSSProxyActions = contract.fromArtifact('DssProxyActions');
const MCDSaverTaker = contract.fromArtifact('MCDSaverTaker');

const mcdSaverTakerAddr = '0x966d3e76E7a890A2d7B9AE1E370dC219E920F9D4';
const uniswapWrapperAddr = '0x880A845A85F843a5c67DB2061623c6Fc3bB4c511';

const makerVersion = "1.0.9";

describe("MCD-Saver", accounts => {
    let registry, proxy, proxyAddr, makerAddresses,
        web3LoanInfo, web3Exchange, collToken, boostAmount, borrowToken, repayAmount,
        collAmount, borrowAmount, getCdps, mcdSaverTaker, tokenId;

    before(async () => {
    	makerAddresses = await fetchMakerAddresses(makerVersion);

        web3 = loadAccounts(web3);
        accounts = getAccounts(web3);

        registry = await ProxyRegistryInterface.at(makerAddresses["PROXY_REGISTRY"]);

        const proxyInfo = await getProxy(registry, accounts[0]);
        proxy = proxyInfo.proxy;
        proxyAddr = proxyInfo.proxyAddr;
        web3Proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);
        getCdps = await GetCdps.at(makerAddresses["GET_CDPS"]);
        web3Exchange = new web3.eth.Contract(ExchangeInterface.abi, uniswapWrapperAddr);
        mcdSaverTaker = await MCDSaverTaker.at(mcdSaverTakerAddr);

        tokenId = "ETH_A";

        collToken = ETH_ADDRESS;
        borrowToken = makerAddresses["MCD_DAI"];

        boostAmount = web3.utils.toWei('200', 'ether');
        repayAmount = web3.utils.toWei('0.3', 'ether');

        collAmount = web3.utils.toWei('2', 'ether');
        borrowAmount = web3.utils.toWei('200', 'ether');
    });

    // it('... should buy a token', async () => {
    //     const ethAmount = web3.utils.toWei('5', 'ether');
    //     await web3Exchange.methods.swapEtherToToken(ethAmount, collToken, '0').send({from: accounts[0], value: ethAmount, gas: 800000});

    //     const tokenBalance = await getBalance(web3, accounts[0], collToken);
    //     console.log(tokenBalance/ 1e18);
    //     expect(tokenBalance).to.be.bignumber.is.above('0');
    // });

    // it('... should call Boost', async () => {
    //     const vaultId = await createVault(tokenId, collAmount, borrowAmount);
    //     const ratioBefore = await getRatio(vaultId);
    //     console.log(ratioBefore);

    //     const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(mcdSaverTaker, 'boostWithLoan'),
    //     [vaultId, 0, makerAddresses[`MCD_JOIN_${tokenId}`],
    //     [makerAddresses["MCD_DAI"], collToken, boostAmount, 0, 0, uniswapWrapperAddr, nullAddress, "0x0", 0]]);

    //     await web3Proxy.methods['execute(address,bytes)']
    //         (mcdSaverTakerAddr, data).send({from: accounts[0], gas: 3500000});

    //     const ratioAfter = await getRatio(vaultId);
    //     console.log(ratioAfter);

    //     expect(ratioBefore).is.above(ratioAfter);
    // });

    // it('... should call Repay', async () => {
    //     const vaultId = await createVault(tokenId, collAmount, (borrowAmount * 2).toString());
    //     const ratioBefore = await getRatio(vaultId);
    //     console.log(ratioBefore);

    //     const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(mcdSaverTaker, 'repayWithLoan'),
    //     [vaultId, 0, makerAddresses[`MCD_JOIN_${tokenId}`],
    //     [collToken, makerAddresses["MCD_DAI"], repayAmount, 0, 0, uniswapWrapperAddr, nullAddress, "0x0", 0]]);

    //     await web3Proxy.methods['execute(address,bytes)']
    //         (mcdSaverTakerAddr, data).send({from: accounts[0], gas: 3500000});

    //     const ratioAfter = await getRatio(vaultId);
    //     console.log(ratioAfter);

    //     expect(ratioBefore).is.below(ratioAfter);
    // });

    // it('... should call flash Boost', async () => {
    //     const vaultId = await createVault(tokenId, collAmount, Dec(borrowAmount).times(2).toString());
    //     const ratioBefore = await getRatio(vaultId);
    //     console.log(ratioBefore);

    //     const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(mcdSaverTaker, 'boostWithLoan'),
    //     [vaultId, 0, makerAddresses[`MCD_JOIN_${tokenId}`],
    //     [makerAddresses["MCD_DAI"], collToken, Dec(boostAmount).div(2).toString(), 0, 0, uniswapWrapperAddr, nullAddress, "0x0", 0]]);

    //     await web3Proxy.methods['execute(address,bytes)']
    //         (mcdSaverTakerAddr, data).send({from: accounts[0], gas: 3500000});

    //     const ratioAfter = await getRatio(vaultId);
    //     console.log(ratioAfter);

    //     expect(ratioBefore).is.above(ratioAfter);
    // });

    it('... should call flash Repay', async () => {
        const vaultId = await createVault(tokenId, collAmount, Dec(borrowAmount).times(2.3).toString());
        const ratioBefore = await getRatio(vaultId);
        console.log(ratioBefore);

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(mcdSaverTaker, 'repayWithLoan'),
        [vaultId, 0, makerAddresses[`MCD_JOIN_${tokenId}`],
        [collToken, makerAddresses["MCD_DAI"], repayAmount, 0, 0, uniswapWrapperAddr, nullAddress, "0x0", 0]]);

        await web3Proxy.methods['execute(address,bytes)']
            (mcdSaverTakerAddr, data).send({from: accounts[0], gas: 3500000});

        const ratioAfter = await getRatio(vaultId);
        console.log(ratioAfter);

        expect(ratioBefore).is.below(ratioAfter);
    });


    const getRatio = async (vaultId) => {
        const vaultInfo = await mcdSaverTaker.getCdpDetailedInfo(vaultId);
        let ratio = ((vaultInfo.collateral / 1e18) * vaultInfo.price) / vaultInfo.debt;

        return ratio / 1e7;
    }

    const createVault = async (type, _collAmount, _daiAmount) => {

        let ilk = '0x4554482d41000000000000000000000000000000000000000000000000000000';
        let value = _collAmount;
        let daiAmount = _daiAmount;

    	const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'openLockETHAndDraw'),
         [makerAddresses['CDP_MANAGER'], makerAddresses['MCD_JUG'], makerAddresses["MCD_JOIN_ETH_A"], makerAddresses["MCD_JOIN_DAI"], ilk, daiAmount]);

    	await proxy.methods['execute(address,bytes)'](makerAddresses['PROXY_ACTIONS'], data, {
            from: accounts[0], value});

        const cdpsAfter = await getCdps.getCdpsAsc(makerAddresses['CDP_MANAGER'], proxyAddr);
        return cdpsAfter.ids[cdpsAfter.ids.length - 1].toString()
    }

});
