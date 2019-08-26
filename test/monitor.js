const DSProxy = artifacts.require("./DSProxy.sol");
const ProxyRegistryInterface = artifacts.require("./ProxyRegistryInterface.sol");
const Monitor = artifacts.require("./Monitor.sol");
const MonitorProxy = artifacts.require("./MonitorProxy.sol");
const DecenterMonitorLending = artifacts.require("./DecenterMonitorLending.sol");
const ERC20 = artifacts.require("./ERC20.sol");

contract("Monitor", accounts => {

    let monitor, monitorProxy, registry, proxy, currRatio, daiToken;

    const MONITOR_ADDRESS = "0x320CC1a24834D7a66220F17e861a847D880b3285";

    const cdpIdBytes32 = "0x000000000000000000000000000000000000000000000000000000000000177c";

    let account = accounts[0];

    before(async () => {
        monitor = await Monitor.at(MONITOR_ADDRESS);
        monitorProxy = await MonitorProxy.at("0x348187d81C3931E35AAB5F8CA3A368e9b5a196B5");

        registry = await ProxyRegistryInterface.at("0x64a436ae831c1672ae81f674cab8b6775df3475c");

        daiToken = await ERC20.at('0x25a01a05C188DaCBCf1D61Af55D4a5B4021F7eeD');

        const proxyAddr = await registry.proxies(account);
        proxy = await DSProxy.at(proxyAddr);

    });

    function getAbiFunction(contract, functionName) {
        const abi = contract.toJSON().abi;

        return abi.find(abi => abi.name === functionName);
      }

      it('...should get CDPs ratio', async () => {
        const res = await monitor.getRatio.call(cdpIdBytes32);

        currRatio = res.toString() / 1e18;

        console.log(currRatio);
      });

      it('...should subscribe the CDP for monitoring', async () => {
        const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MonitorProxy, 'subscribe'),
         [cdpIdBytes32,
          web3.utils.toWei('1.80', 'ether'), // minRatio
          web3.utils.toWei('2.0', 'ether'), // maxRatio
          web3.utils.toWei('1.90', 'ether'), // optimalBoostRatio
          web3.utils.toWei('1.90', 'ether'), // optimalRepay Ratio,
          MONITOR_ADDRESS]);

        try {
            const tx = await proxy.methods['execute(address,bytes)'](MonitorProxy.address, data, {from: account});

            const subInfo = await monitor.methods['holders(bytes32)'].call(cdpIdBytes32);

            console.log(subInfo);

        } catch(err) {
            console.log(err);
        }
      });

      it('...should authorize another address to be a caller', async () => {

        try {
            const tx = await monitor.addCaller(accounts[1], {from: account});

        } catch(err) {
            console.log(err);
        }
      });


    //   it('...should call the boostFor method for the user', async () => {

    //     const amount = web3.utils.toWei('12', 'ether'); // 12 dai

    //     try {
    //         const tx = await monitor.boostFor(cdpIdBytes32, amount, {from: accounts[1]});

    //         console.log(tx);


    //     } catch(err) {
    //         console.log(err);
    //     }
    //   });

    //    it('...should call the repayFor method for the user', async () => {
    //     const amount = web3.utils.toWei('0.1', 'ether');

    //     try {
    //         const tx = await monitor.repayFor(cdpIdBytes32, amount, {from: accounts[1]});

    //         console.log(tx);


    //     } catch(err) {
    //         console.log(err);
    //     }
    //   });


});
