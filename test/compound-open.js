let { accounts, contract, web3, provider } = require('@openzeppelin/test-environment');
const { expectEvent, balance, expectRevert, send } = require('@openzeppelin/test-helpers');
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
    getDebugInfo,
    ETH_ADDRESS,
    WETH_ADDRESS,
    C_ETH_ADDRESS,
    BAT_ADDRESS,
    C_BAT_ADDRESS,
    C_DAI_ADDRESS,
    nullAddress,
} = require('./helper.js');
const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');

const DSProxy = contract.fromArtifact("DSProxy");
const ProxyRegistryInterface = contract.fromArtifact("ProxyRegistryInterface");
const CompoundBasicProxy = contract.fromArtifact('CompoundBasicProxy');
const CompoundLoanInfo = contract.fromArtifact('CompoundLoanInfo');
const ExchangeInterface = contract.fromArtifact('ExchangeInterface');
const CTokenInterface = contract.fromArtifact('CTokenInterface');
const ComptrollerInterface = contract.fromArtifact('ComptrollerInterface');
const CompoundCreateTaker = contract.fromArtifact('CompoundCreateTaker');
const CompoundCreateReceiver = contract.fromArtifact('CompoundCreateReceiver');
const ERC20 = contract.fromArtifact('ERC20');

const compoundBasicProxyAddr = '0x0F1e33A36fA6a33Ea01460F04c6D8F1FAc2186E3';
const compoundLoanInfoAddr = '0x4D32ECeC25d722C983f974134d649a20e78B1417';
const uniswapWrapperAddr = '0xB9bdBAEc07751F6d54d19A6B9995708873F3DE18';
const oldUniswapWrapperAddr = '0x1e30124FDE14533231216D95F7798cD0061e5cf8';
const comptrollerAddr = '0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b';

const compoundCreateTakerAddr = '0xe93e3B649d4E01e47dd2170CAFEf0651477649Da';
const compoundCreateReceiverAddr = '0xEd447aCB0CEb49d77f317dD6D37CB64da7a7E7F8';

const makerVersion = "1.0.6";

describe("Compound-Open", accounts => {
    let registry, proxy, proxyAddr, makerAddresses,
        web3LoanInfo, web3Exchange, collToken, cCollAddr, cCollToken, borrowToken, cBorrowAddr, cBorrowToken,
        collAmount, borrowAmount, comptroller;

    const getCompoundRatio = async (addr) => {
        const loanInfo = await web3LoanInfo.methods.getLoanData(addr).call();

        return loanInfo.ratio / 1e16;
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
        comptroller = new web3.eth.Contract(ComptrollerInterface.abi, comptrollerAddr);
        web3LoanInfo = new web3.eth.Contract(CompoundLoanInfo.abi, compoundLoanInfoAddr);
        web3Exchange = new web3.eth.Contract(ExchangeInterface.abi, oldUniswapWrapperAddr);
        daiToken = new web3.eth.Contract(ERC20.abi, makerAddresses["MCD_DAI"]);

        compoundReceiver = new web3.eth.Contract(CompoundCreateReceiver.abi, compoundCreateReceiverAddr);

        collToken = ETH_ADDRESS;
        borrowToken = makerAddresses["MCD_DAI"];
        cCollAddr = C_ETH_ADDRESS;
        cBorrowAddr = C_DAI_ADDRESS;

        cCollToken = new web3.eth.Contract(CTokenInterface.abi, cCollAddr);
        cBorrowToken = new web3.eth.Contract(CTokenInterface.abi, cBorrowAddr);

    });

    it('... should buy a token', async () => {
        const ethAmount = web3.utils.toWei('2', 'ether');
        await web3Exchange.methods.swapEtherToToken(ethAmount, borrowToken, '0').send({from: accounts[0], value: ethAmount, gas: 800000});

        // await daiToken.methods.transfer(compoundCreateReceiverAddr, web3.utils.toWei('200', 'ether')).send({from: accounts[0], gas: 200000});

        // await send.ether(accounts[0], compoundCreateReceiverAddr, web3.utils.toWei('2', 'ether'));

        // const tokenBalance = await getBalance(web3, accounts[0], borrowToken);
        // console.log(tokenBalance/ 1e18);
        // expect(tokenBalance).to.be.bignumber.is.above('0');
    });

    // it('... should open a leveraged long position', async () => {

    //     let srcAmount = web3.utils.toWei('1', 'ether');
    //     let destAmount = web3.utils.toWei('100', 'ether');

    //     const createData = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundCreateTaker, 'openLeveragedLoan'),
    //     [[cCollAddr, cBorrowAddr, 0], [borrowToken, collToken, destAmount, 0, 0, uniswapWrapperAddr, ZERO_ADDRESS, "0x0", 0], compoundCreateReceiverAddr]);

    //    await web3Proxy.methods['execute(address,bytes)']
    //     (compoundCreateTakerAddr, createData).send({from: accounts[0], gas: 3500000, value: srcAmount});

    // });

    it('... should open a leveraged short position', async () => {

        const tokenBalance = await getBalance(web3, accounts[0], borrowToken);
        console.log(tokenBalance/ 1e18);

        await approve(web3, borrowToken, accounts[0], proxyAddr);

        let srcAmount = web3.utils.toWei('100', 'ether');
        let destAmount = web3.utils.toWei('1', 'ether');

        const createData = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundCreateTaker, 'openLeveragedLoan'),
        [[cBorrowAddr, cCollAddr, srcAmount], [collToken, borrowToken, destAmount, 0, 0, uniswapWrapperAddr, ZERO_ADDRESS, "0x0", 0], compoundCreateReceiverAddr]);

       await web3Proxy.methods['execute(address,bytes)']
        (compoundCreateTakerAddr, createData).send({from: accounts[0], gas: 3500000 });

        console.log("_amount", (await getDebugInfo("_amount", 'uint')) / 1e18);
        console.log("_cTokenAddr", (await getDebugInfo("_cTokenAddr", 'addr')));
        console.log("_tokenAddr", (await getDebugInfo("_tokenAddr", 'addr')));
        console.log("contractAddr", (await getDebugInfo("contractAddr", 'addr')));

    });

});
