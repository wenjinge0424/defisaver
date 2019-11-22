

const Web3 = require('web3');

require('dotenv').config();

const DSProxy = require('../build/contracts/DSProxy.json');
const ProxyRegistryInterface = require('../build/contracts/ProxyRegistryInterface.json');
const DSSProxyActions = require('../build/contracts/DSSProxyActions.json');
const MCDSaverProxy = require('../build/contracts/MCDSaverProxy.json');


const initContracts = async () => {
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.INFURA_ENDPOINT));

    account = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY)
    web3.eth.accounts.wallet.add(account)

    registry = new web3.eth.Contract(ProxyRegistryInterface.abi, '0x4678f0a6958e4d2bc4f1baf7bc52e8f3564f3fe4');

    proxyAddr = await registry.methods.proxies(account.address).call();
    proxy = new web3.eth.Contract(DSProxy.abi, proxyAddr);

    mcdSaverProxy = new web3.eth.Contract(MCDSaverProxy.abi, '0x260c1543743fd03cd98a1d1edc3a4724af0a1fce');
};

function getAbiFunction(contract, functionName) {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}

const getRatio = async (cdpId) => {
    const cdpInfo = await mcdSaverProxy.methods.getCdpDetailedInfo(cdpId).call();

     console.log(cdpInfo.debt / 1e18);

    return ((cdpInfo.collateral * (cdpInfo.price / 1e27)) /  cdpInfo.debt) * 100;
}

const ratioAfterPayback = async (cdpId, amount) => {
    const cdpInfo = await mcdSaverProxy.methods.getCdpDetailedInfo(cdpId).call();
    const payedDebt = web3.utils.toWei(amount, 'ether');

    return ((cdpInfo.collateral * (cdpInfo.price / 1e27)) /  (cdpInfo.debt - payedDebt)) * 100;
};

(async () => {
    await initContracts();

    let affected = [683, 954, 626, 562];

    const ratio1 = await getRatio(affected[0]);
    const ratio2 = await getRatio(affected[1]);
    const ratio3 = await getRatio(affected[2]);
    const ratio4 = await getRatio(affected[3]);

    console.log(ratio1, ratio2, ratio3, ratio4);

    // const ratioAfter = await ratioAfterPayback(affected[0], '30');
    // console.log(ratioAfter);

   //  await payback(affected[2], '20');

})();

const payback = async (cdpId, daiAmount) => {
    try {
        // await approveToken('DAI');

        daiAmount = web3.utils.toWei(daiAmount, 'ether');

        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'wipe'),
          ['0x5ef30b9986345249bc32d8928b7ee64de9435e39', '0x9759a6ac90977b93b58547b4a71c78317f391a28', cdpId, daiAmount]);

        const tx = await proxy.methods['execute(address,bytes)']('0xa483cfe6403949bf38c74f8c340651fb02246d21', data).send({
            from: account.address, gas: 400000});

        console.log(tx);
    } catch(err) {
        console.log(err);
    }
};
