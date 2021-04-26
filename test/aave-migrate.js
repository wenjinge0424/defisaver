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


describe("AAVE-Migration", function() {
    this.timeout(600000);

    let senderAcc, proxy, aaveMigrationTaker, aaveLoanInfo, aaveMigrationReceiver, aaveMigration;

    const raiAddr = '0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919';
    const ethAddr = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
    const UNISWAP_WRAPPER = '0x6403BD92589F825FfeF6b62177FCe9149947cb9f';

    const user = '';

    const marketAddr = '0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5';


    before(async () => {

        senderAcc = (await hre.ethers.getSigners())[0];

        aaveMigrationTaker = await deployContract("AaveMigrationTaker");
        aaveMigrationReceiver = await deployContract("AaveMigrationReceiver");
        aaveMigration = await deployContract("AaveMigration");
        aaveLoanInfo = await deployContract("AaveLoanInfo");

        await aaveMigrationReceiver.setAaveMigrationAddr(aaveMigration.address);

        await impersonateAccount(user);

        senderAcc = await hre.ethers.provider.getSigner(user);
        proxy = await getProxyWithSigner(senderAcc, user);

        proxy.connect(senderAcc);

        console.log('Proxy: ', proxy.address);
    });


    it('... should migrate AAVE V1 -> AAVE V2', async () => {

        // migrateV1Position(
        //     address _market,
        //     address[] memory _collTokens,
        //     address[] memory _borrowTokens,
        //     uint256[] memory _flModes,
        //     address _aaveMigrationAddr

        const userData = await aaveLoanInfo.getLoanData(proxy.address);
        // console.log(userData);

        const borrowTokens = [];
        const collTokens = [];
        const flModes = [];
        const isColl = [];

        userData.borrowAddr.forEach(borrowAddr => {
            if (borrowAddr !== nullAddress) {
                borrowTokens.push(borrowAddr);
                flModes.push(0);
            }
        });

        userData.collAddr.forEach(collAddr => {
            if (collAddr !== nullAddress) {
                collTokens.push(collAddr);
                isColl.push(true);
            }
        });

        console.log(borrowTokens, collTokens);

        const AaveMigrationTaker = await ethers.getContractFactory("AaveMigrationTaker");
        const functionData = AaveMigrationTaker.interface.encodeFunctionData(
            "migrateV1Position",
                [marketAddr, collTokens, isColl, borrowTokens, flModes, aaveMigrationReceiver.address]
        );

        await proxy["execute(address,bytes)"](aaveMigrationTaker.address, functionData, {
            gasLimit: 5000000,
        });
    }).timeout(100000);


});
