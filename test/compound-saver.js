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
    C_ETH_ADDRESS,
    BAT_ADDRESS,
    C_BAT_ADDRESS,
    C_DAI_ADDRESS,
    nullAddress,
} = require('./helper.js');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const CompoundBasicProxy = contract.fromArtifact('CompoundBasicProxy');
const CompoundFlashLoanTaker = contract.fromArtifact('CompoundFlashLoanTaker');
const CompoundLoanInfo = contract.fromArtifact('CompoundLoanInfo');
const ExchangeInterface = contract.fromArtifact('ExchangeInterface');

const compoundBasicProxyAddr = '0x0F1e33A36fA6a33Ea01460F04c6D8F1FAc2186E3';
const compoundLoanInfoAddr = '0x4D32ECeC25d722C983f974134d649a20e78B1417';
const compoundFlashLoanTakerAddr = '0xbA6a725BAe83D8879610D1E957253e195d6e4b71';
const uniswapWrapperAddr = '0x1e30124FDE14533231216D95F7798cD0061e5cf8';

const makerVersion = "1.0.6";

describe("Compound-Saver", accounts => {
    let registry, proxy, proxyAddr, makerAddresses,
        web3LoanInfo, web3Exchange, collToken, cCollToken, borrowToken, cBorrowToken,
        collAmount, borrowAmount;

    const getCompoundRatio = async () => {
        const loanInfo = await web3LoanInfo.methods.getLoanData(proxyAddr).call();

        return loanInfo.ratio / 1e16;
    };

    const getMaxColl = async () => {
        const maxColl = await web3LoanInfo.methods.getMaxCollateral(cCollToken, proxyAddr).call();

        return maxColl / 1e18;
    };

    const getMaxBorrow = async () => {
        const maxBorrow = await web3LoanInfo.methods.getMaxBorrow(cBorrowToken, proxyAddr).call();

        return maxBorrow / 1e18;
    };

    before(async () => {
    	makerAddresses = await fetchMakerAddresses(makerVersion);

        web3 = loadAccounts(web3);
        accounts = getAccounts(web3);

        registry = await ProxyRegistryInterface.at(makerAddresses["PROXY_REGISTRY"]);

        const proxyInfo = await getProxy(registry, accounts[0]);
        proxy = proxyInfo.proxy;
        proxyAddr = proxyInfo.proxyAddr;
        web3Proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);
        web3LoanInfo = new web3.eth.Contract(CompoundLoanInfo.abi, compoundLoanInfoAddr);
        web3Exchange = new web3.eth.Contract(ExchangeInterface.abi, uniswapWrapperAddr);

        collToken = BAT_ADDRESS;
        borrowToken = makerAddresses["MCD_DAI"];
        cCollToken = C_BAT_ADDRESS;
        cBorrowToken = C_DAI_ADDRESS;

        collAmount = web3.utils.toWei('1000', 'ether');
        borrowAmount = web3.utils.toWei('20', 'ether');
    });

    it('... should buy a token', async () => {
        const ethAmount = web3.utils.toWei('5', 'ether');
        await web3Exchange.methods.swapEtherToToken(ethAmount, collToken, '0').send({from: accounts[0], value: ethAmount, gas: 800000});

        const tokenBalance = await getBalance(web3, accounts[0], collToken);
        console.log(tokenBalance/ 1e18);
        expect(tokenBalance).to.be.bignumber.is.above('0');
    });

    it('... should create a compound position', async () => {

        let ethValue = 0;
        if (collToken === ETH_ADDRESS) {
            ethValue = collAmount;
        } else {
            await approve(web3, collToken, accounts[0], proxyAddr);
        }

        const depositData = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundBasicProxy, 'deposit'),
         [collToken, cCollToken, collAmount, false]);
        await web3Proxy.methods['execute(address,bytes)']
            (compoundBasicProxyAddr, depositData).send({from: accounts[0], value: ethValue, gas: 3500000});

        const borrowData = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundBasicProxy, 'borrow'),
         [borrowToken, C_DAI_ADDRESS, borrowAmount, false]);
        await web3Proxy.methods['execute(address,bytes)']
            (compoundBasicProxyAddr, borrowData).send({from: accounts[0], gas: 3500000});

        const ratio = await getCompoundRatio();
        console.log(ratio);

        expect(ratio).is.above(0);
    });

    it('... should call Boost', async () => {
        const amountBorrow = (borrowAmount / 10).toString();

        const ratioBefore = await getCompoundRatio();
        console.log(ratioBefore);

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundFlashLoanTaker, 'boostWithLoan'),
        [[amountBorrow, 0, 0, 0, 0], [cCollToken, cBorrowToken, nullAddress], '0x0']);

        await web3Proxy.methods['execute(address,bytes)']
            (compoundFlashLoanTakerAddr, data).send({from: accounts[0], gas: 3500000});

        const ratioAfter = await getCompoundRatio();
        console.log(ratioAfter);

        expect(ratioBefore).is.above(ratioAfter);
    });

    it('... should call Repay', async () => {
        const amountColl = (collAmount / 10).toString();

        const ratioBefore = await getCompoundRatio();
        console.log(ratioBefore);

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundFlashLoanTaker, 'repayWithLoan'),
        [[amountColl, 0, 0, 0, 0], [cCollToken, cBorrowToken, nullAddress], '0x0']);

        await web3Proxy.methods['execute(address,bytes)']
            (compoundFlashLoanTakerAddr, data).send({from: accounts[0], gas: 3500000});

        const ratioAfter = await getCompoundRatio();
        console.log(ratioAfter);

        expect(ratioAfter).is.above(ratioBefore);
    });

    it('... should call Flash boost', async () => {
        const maxBorrow = await getMaxBorrow();
        const amountBorrow = web3.utils.toWei((maxBorrow * 1.2).toString(), 'ether');

        const ratioBefore = await getCompoundRatio();
        console.log(ratioBefore);

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundFlashLoanTaker, 'boostWithLoan'),
        [[amountBorrow, 0, 0, 0, 0], [cCollToken, cBorrowToken, nullAddress], '0x0']);

        await web3Proxy.methods['execute(address,bytes)']
            (compoundFlashLoanTakerAddr, data).send({from: accounts[0], gas: 3500000});

        const ratioAfter = await getCompoundRatio();
        console.log(ratioAfter);

        expect(ratioBefore).is.above(ratioAfter);
    });

    it('... should call Flash repay', async () => {
        const maxColl = await getMaxColl();
        const amountColl = web3.utils.toWei((maxColl * 1.2).toString(), 'ether');

        const ratioBefore = await getCompoundRatio();
        console.log(ratioBefore);

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundFlashLoanTaker, 'repayWithLoan'),
        [[amountColl, 0, 0, 0, 0], [cCollToken, cBorrowToken, nullAddress], '0x0']);

        await web3Proxy.methods['execute(address,bytes)']
            (compoundFlashLoanTakerAddr, data).send({from: accounts[0], gas: 3500000});

        const ratioAfter = await getCompoundRatio();
        console.log(ratioAfter);

        expect(ratioAfter).is.above(ratioBefore);
    });

    it('... should revert repay if value to large', async () => {
        const amountColl = web3.utils.toWei((collAmount / 1e18 * 10).toString(), 'ether');

        const ratioBefore = await getCompoundRatio();
        console.log(ratioBefore);

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundFlashLoanTaker, 'repayWithLoan'),
        [[amountColl, 0, 0, 0, 0], [cCollToken, cBorrowToken, nullAddress], '0x0']);

        try {
            await web3Proxy.methods['execute(address,bytes)']
                (compoundFlashLoanTakerAddr, data).send({from: accounts[0], gas: 3500000});

            expect(0).is.above(1);
        } catch(err) {
            expect(1).is.above(0);
        }

    });

});
