const KyberWrapper = artifacts.require("./KyberWrapper.sol");
const UniswapWrapper = artifacts.require("./UniswapWrapper.sol");
const OasisTradeWrapper = artifacts.require("./OasisTradeWrapper.sol");
const SaverExchange = artifacts.require("./SaverExchange.sol");
const SaverExchangeRegistry = artifacts.require("./SaverExchangeRegistry.sol");
const AllowanceProxy = artifacts.require("./AllowanceProxy.sol");
const Prices = artifacts.require("./Prices.sol");

require('dotenv').config();

module.exports = function(deployer, network, accounts) {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    // needs to be set in tests and approved
    const allowanceAddr = '0xC3Ef4965B788cc4b905084d01F2eb7D4b6E93ABF';

    // the same needs to be set in the contract
    const registryAddr = '0x4bf3A7dFB3b76b5B3E169ACE65f888A4b4FCa5Ee';

    deployer.then(async () => {
         // Step 1. deploy allowance and add addres here
        // await deployer.deploy(AllowanceProxy, {gas: 6720000, overwrite: deployAgain});

        // Step 2
        const allowanceContract = await AllowanceProxy.at(allowanceAddr);

        await deployer.deploy(Prices, {gas: 6720000, overwrite: deployAgain});


        // await deployer.deploy(SaverExchange, {gas: 6720000, overwrite: deployAgain});
        // const saverExchangeAddr = (await SaverExchange.deployed()).address;

        // await allowanceContract.ownerChangeExchange(saverExchangeAddr);

        // // deploy wrappers
        // await deployer.deploy(UniswapWrapper, {gas: 6720000, overwrite: deployAgain});
        // await deployer.deploy(KyberWrapper, {gas: 6720000, overwrite: deployAgain});
        // await deployer.deploy(OasisTradeWrapper, {gas: 6720000, overwrite: deployAgain});

        // const registry = await SaverExchangeRegistry.at(registryAddr);

        // const uniswapWrapperAddr = (await UniswapWrapper.deployed()).address;
        // console.log('UniswapWrapper: ',uniswapWrapperAddr);
        // await registry.addWrapper(uniswapWrapperAddr);

        // const kyberWrapperAddr = (await KyberWrapper.deployed()).address;
        // console.log('KyberWrapper: ',kyberWrapperAddr);
        // await registry.addWrapper(kyberWrapperAddr);

        // const oasisTradeWrapperAddr = (await OasisTradeWrapper.deployed()).address;
        // console.log('OasisTradeWrapper: ',oasisTradeWrapperAddr);
        // await registry.addWrapper(oasisTradeWrapperAddr);
    });
};
