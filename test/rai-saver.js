const hre = require("hardhat");

const nullAddress = '0x0000000000000000000000000000000000000000';
const WETH_ADDRESS = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';

const { deployContract } = require("../deployers/utils/deployer");

const impersonateAccount = async (account) => {
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [account]}
    );
};

const stopImpersonatingAccount = async (account) => {
    await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [account]}
    );
};

const getProxy = async (acc) => {
    const proxyRegistry = await
    hre.ethers.getContractAt("contracts/interfaces/ProxyRegistryInterface.sol:ProxyRegistryInterface", "0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4");

    let proxyAddr = await proxyRegistry.proxies(acc);

    if (proxyAddr == nullAddress) {
        await proxyRegistry.build(acc);
        proxyAddr = await proxyRegistry.proxies(acc);
    }

    const dsProxy = await hre.ethers.getContractAt("contracts/DS/DSProxy.sol:DSProxy", proxyAddr);

    return dsProxy;
};

const getProxyWithSigner = async (signer, addr) => {
    const proxyRegistry = await
    hre.ethers.getContractAt("contracts/interfaces/ProxyRegistryInterface.sol:ProxyRegistryInterface", "0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4");

    let proxyAddr = await proxyRegistry.proxies(addr);

    if (proxyAddr == nullAddress) {
        await proxyRegistry.build(addr);
        proxyAddr = await proxyRegistry.proxies(addr);
    }

    const dsProxy = await hre.ethers.getContractAt("contracts/DS/DSProxy.sol:DSProxy", proxyAddr, signer);

    return dsProxy;
}

const formatExchangeObj = (srcAddr, destAddr, amount, wrapper, destAmount = 0) => {
    const abiCoder = new ethers.utils.AbiCoder();

    let firstPath = srcAddr;
    let secondPath = destAddr;

    if (srcAddr.toLowerCase() === "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee") {
        firstPath = WETH_ADDRESS;
    }

    if (destAddr.toLowerCase() === "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee") {
        secondPath = WETH_ADDRESS;
    }

    const path = abiCoder.encode(['address[]'],[[firstPath, secondPath]]);

    return [
        srcAddr,
        destAddr,
        amount,
        destAmount,
        0,
        0,
        nullAddress,
        wrapper,
        path,
        [nullAddress, nullAddress, nullAddress, 0, 0, ethers.utils.toUtf8Bytes('')]
    ];
};


describe("RAI-Saver", function() {
    this.timeout(60000);

    let senderAcc, proxy, raiSaverTaker, raiSaverFlashLoan;

    const raiAddr = '0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919';
    const ethAddr = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
    const UNISWAP_WRAPPER = '0x6403BD92589F825FfeF6b62177FCe9149947cb9f';


    before(async () => {

        senderAcc = (await hre.ethers.getSigners())[0];

        raiSaverTaker = await deployContract("RAISaverTaker");
        raiSaverFlashLoan = await deployContract("RAISaverFlashLoan");

        // Send Weth dust to receiver contract
        const weth = await hre.ethers.getContractAt("TokenInterface", WETH_ADDRESS);
        const ethAmount = "20";
        await weth.deposit({value: ethAmount});

        const tokenContract = await hre.ethers.getContractAt("Gem", WETH_ADDRESS);
        await tokenContract.transfer(raiSaverFlashLoan.address, ethAmount);

        const TEST_ACC = '0x0a80C3C540eEF99811f4579fa7b1A0617294e06f';

        await impersonateAccount(TEST_ACC);

        senderAcc = await hre.ethers.provider.getSigner(TEST_ACC);
        proxy = await getProxyWithSigner(senderAcc, TEST_ACC);

        proxy.connect(senderAcc);
    });



    // it('... should call Boost', async () => {

    //     const safeId = '1031';
    //     const joinAddr = '0x2D3cD7b81c93f188F3CB8aD87c8Acc73d6226e3A';
    //     const gasCost = 0;
    //     const managerType = 0;

    //     const boostAmount = ethers.utils.parseUnits('50', 18);

    //     const exData = formatExchangeObj(
    //         raiAddr,
    //         ethAddr,
    //         boostAmount,
    //         UNISWAP_WRAPPER
    //     );

    //     const RAISaverTaker = await ethers.getContractFactory("RAISaverTaker");
    //     const functionData = RAISaverTaker.interface.encodeFunctionData(
    //         "boostWithLoan",
    //             [exData, safeId, gasCost, joinAddr, managerType]
    //     );

    //     await proxy["execute(address,bytes)"](raiSaverTaker.address, functionData, {
    //         gasLimit: 3000000,
    //     });
    // });

    // it('... should call Repay', async () => {
    //     const safeId = '1031';
    //     const joinAddr = '0x2D3cD7b81c93f188F3CB8aD87c8Acc73d6226e3A';
    //     const gasCost = 0;
    //     const managerType = 0;

    //     const repayAmount = ethers.utils.parseUnits('0.1', 18);

    //     const exData = formatExchangeObj(
    //         ethAddr,
    //         raiAddr,
    //         repayAmount,
    //         UNISWAP_WRAPPER
    //     );

    //     const RAISaverTaker = await ethers.getContractFactory("RAISaverTaker");
    //     const functionData = RAISaverTaker.interface.encodeFunctionData(
    //         "repayWithLoan",
    //             [exData, safeId, gasCost, joinAddr, managerType]
    //     );

    //     await proxy["execute(address,bytes)"](raiSaverTaker.address, functionData, {
    //         gasLimit: 3000000,
    //     });
    // });

    // it('... should call FL Boost', async () => {
    //     const safeId = '1031';
    //     const joinAddr = '0x2D3cD7b81c93f188F3CB8aD87c8Acc73d6226e3A';
    //     const gasCost = 0;
    //     const managerType = 0;

    //     const boostAmount = ethers.utils.parseUnits('1150', 18);

    //     const exData = formatExchangeObj(
    //         raiAddr,
    //         ethAddr,
    //         boostAmount,
    //         UNISWAP_WRAPPER
    //     );


    //     const RAISaverTaker = await ethers.getContractFactory("RAISaverTaker");
    //     const functionData = RAISaverTaker.interface.encodeFunctionData(
    //         "boostWithLoan",
    //             [exData, safeId, gasCost, joinAddr, managerType, raiSaverFlashLoan.address]
    //     );

    //     await proxy["execute(address,bytes)"](raiSaverTaker.address, functionData, {
    //         gasLimit: 3000000,
    //     });
    // });


      it('... should call Repay', async () => {
        const safeId = '1031';
        const joinAddr = '0x2D3cD7b81c93f188F3CB8aD87c8Acc73d6226e3A';
        const gasCost = 0;
        const managerType = 0;

        const repayAmount = ethers.utils.parseUnits('2.2', 18);

        const exData = formatExchangeObj(
            ethAddr,
            raiAddr,
            repayAmount,
            UNISWAP_WRAPPER
        );

        const RAISaverTaker = await ethers.getContractFactory("RAISaverTaker");
        const functionData = RAISaverTaker.interface.encodeFunctionData(
            "repayWithLoan",
                [exData, safeId, gasCost, joinAddr, managerType, raiSaverFlashLoan.address]
        );

        await proxy["execute(address,bytes)"](raiSaverTaker.address, functionData, {
            gasLimit: 3000000,
        });
    });


});
