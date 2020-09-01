const MCDCloseTaker = artifacts.require("./MCDCloseTaker.sol");
const MCDCloseFlashLoan = artifacts.require("./MCDCloseFlashLoan.sol");
const UniswapWrapper = artifacts.require("./UniswapWrapper.sol");
const KyberWrapper = artifacts.require("./KyberWrapper.sol");
const OasisTradeWrapper = artifacts.require("./OasisTradeWrapper.sol");
const SaverExchangeRegistry = artifacts.require("./SaverExchangeRegistry.sol");


module.exports = async (deployer, network, accounts) => {
    let deployAgain = (process.env.DEPLOY_AGAIN === 'true') ? true : false;

    // Step 1. Deploy this and change in contract code
    // deployer.deploy(MCDCloseFlashLoan, {gas: 6720000, overwrite: deployAgain});

    // // Step 2.
    // deployer.deploy(MCDCloseTaker, {gas: 6720000, overwrite: deployAgain});

    await deployer.deploy(OasisTradeWrapper, {gas: 6720000, overwrite: deployAgain});
    const registry = await SaverExchangeRegistry.at('0x4bf3A7dFB3b76b5B3E169ACE65f888A4b4FCa5Ee');

    const uniswapWrapperAddr = (await OasisTradeWrapper.deployed()).address;
    console.log('UniswapWrapper: ',uniswapWrapperAddr);
 	await registry.addWrapper(uniswapWrapperAddr);

};
