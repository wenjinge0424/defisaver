const CTokenInterface = artifacts.require("./CTokenInterface.sol");
const ERC20 = artifacts.require("./ERC20.sol");
const CompoundProxy = artifacts.require("./CompoundProxy.sol");
const DSProxy = artifacts.require("./DSProxy.sol");
const ProxyRegistryInterface = artifacts.require("./ProxyRegistryInterface.sol");
const ComptrollerInterface = artifacts.require("./ComptrollerInterface.sol");
const PriceOracleInterface = artifacts.require("./PriceOracleInterface.sol");

contract("SaverProxy", accounts => {

    let cDaiContract, registry, proxy, compoundProxy, comptrollerInterface;
    const cDaiAddress = "0xb6b09fbffba6a5c4631e5f7b2e3ee183ac259c0d";
    const daiAddress = "0x25a01a05C188DaCBCf1D61Af55D4a5B4021F7eeD";

    // Rinkeby
    // const cDaiAddress = "0x6d7f0754ffeb405d23c51ce938289d4835be3b14";
    // const daiAddress = "0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea";
    // const comptrollerAddress = "0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb";

    const BLOCKS_IN_A_YEAR = 365 * 24 * 60 * 60 / 15;

    const cdpIdBytes32 = "0x0000000000000000000000000000000000000000000000000000000000001751";
    // const cdpIdBytes32 = "0x000000000000000000000000000000000000000000000000000000000000146f";

    let account = accounts[0];

    before(async () => {
        cDaiContract = await CTokenInterface.at(cDaiAddress);
        daiContract = await ERC20.at(daiAddress);
        compoundProxy = await CompoundProxy.at("0x0b79e04F3e42cA3ee47Bc32CbA81eFc55e03D1EC");

        registry = await ProxyRegistryInterface.at("0x64a436ae831c1672ae81f674cab8b6775df3475c");

        comptrollerInterface = await ComptrollerInterface.at(comptrollerAddress);

        const proxyAddr = await registry.proxies(account);
        proxy = await DSProxy.at(proxyAddr);
       
    });

    function getAbiFunction(contract, functionName) {
        const abi = contract.toJSON().abi;
    
        return abi.find(abi => abi.name === functionName);
      }

      it('...should get accontLiquidity', async () => {
        const res = await comptrollerInterface.getAccountLiquidity.call(account);

        console.log(res[1].toString());
      });   


    // it('...should draw Dai from CDP and add to Compound', async () => {
    //     const amount = web3.utils.toWei("0.1", 'ether');

    //     const balanceUnderlying = await cDaiContract.balanceOfUnderlying.call(account);
    //     const supplied = web3.utils.fromWei(balanceUnderlying.toString(), 'ether');
    //     console.log(supplied);

    //     const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundProxy, 'cdpToCompound'), [cdpIdBytes32, amount]);

    //     try {
    //         const tx = await proxy.methods['execute(address,bytes)'](CompoundProxy.address, data, {from: account});

    //         const balanceUnderlying = await cDaiContract.balanceOfUnderlying.call(account);
    //         const supplied = web3.utils.fromWei(balanceUnderlying.toString(), 'ether');
    //         console.log(supplied);
    //     } catch(err) {
    //         console.log(err);
    //     }
    // });

    // it('...should draw Dai from Compound and add to CDP', async () => {
    //     const amount = web3.utils.toWei("0.1", 'ether');

    //     const balanceUnderlying = await cDaiContract.balanceOfUnderlying.call(account);
    //     const supplied = web3.utils.fromWei(balanceUnderlying.toString(), 'ether');
    //     console.log(supplied);

    //     console.log('Proxy: ', proxy.address);

    //     await cDaiContract.approve(proxy.address, web3.utils.toWei(Number.MAX_SAFE_INTEGER.toString(), 'ether'), {from: account});

    //     const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(CompoundProxy, 'repayCDPDebt'), [cdpIdBytes32, amount]);

    //     try {
    //         const tx = await proxy.methods['execute(address,bytes)'](CompoundProxy.address, data, {from: account});

    //         const balanceUnderlying = await cDaiContract.balanceOfUnderlying.call(account);
    //         const supplied = web3.utils.fromWei(balanceUnderlying.toString(), 'ether');
    //         console.log(supplied);
    //     } catch(err) {
    //         console.log(err);
    //     }
    // });


    // it('...should print info', async () => {
    //     const balance = await cDaiContract.balanceOf.call(accounts[0]);
    //     const balanceUnderlying = await cDaiContract.balanceOfUnderlying.call(accounts[0]);
    //     const exchangeRate = (await cDaiContract.exchangeRateCurrent.call()) / 1e18;
    //     const supplyRate = (await cDaiContract.supplyRatePerBlock.call()) / 1e18;
    //     const borrowRate = (await cDaiContract.borrowRatePerBlock.call()) / 1e18;

    //     const supplyPercentage = ((BLOCKS_IN_A_YEAR * supplyRate));

    //     const supplied = web3.utils.fromWei(balanceUnderlying.toString(), 'ether');

    //     const earnedInAYear = (supplied*(1+ supplyPercentage)) - supplied;

    //     console.log(`Account:  ${parseFloat(supplied).toFixed(4)} Dai`);
    //     console.log(`Supply rate: ${(supplyPercentage * 100).toFixed(2)}%`);
    //     console.log(`Earned In a week: ${(earnedInAYear/52.1429).toFixed(4)} DAI`);
    //     console.log(`Earned In a month: ${(earnedInAYear/12).toFixed(2)} DAI`);
    //     console.log(`Earned In a year: ${earnedInAYear.toFixed(2)} DAI`);
    //     console.log(`Borrow rate: ${((BLOCKS_IN_A_YEAR * borrowRate) * 100).toFixed(2)}%`);
    // });

    it('...should supply some Dai to Compound', async () => {
        try {
            await daiContract.approve(cDaiAddress, web3.utils.toWei(Number.MAX_SAFE_INTEGER.toString(), 'ether'));

            // Mint 10 dai
            const res = await cDaiContract.mint(web3.utils.toWei("10", 'ether'), {from: accounts[0]});

            const balance = await cDaiContract.balanceOf.call(accounts[0]);

            const exchangeRate = (await cDaiContract.exchangeRateCurrent.call()) / 1e18;

            console.log(exchangeRate, balance.toString());

            console.log(web3.utils.fromWei((balance * exchangeRate).toString(), 'ether'));
        } catch(err) {
            console.log(err);
        }
    });

});