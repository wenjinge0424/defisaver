const DSProxy = artifacts.require("./DSProxy.sol");
const ProxyRegistryInterface = artifacts.require("./ProxyRegistryInterface.sol");
const Monitor = artifacts.require("./Monitor.sol");
const MonitorProxy = artifacts.require("./MonitorProxy.sol");


contract("Monitor", accounts => {

    let monitor, monitorProxy, registry, proxy;

    const MONITOR_ADDRESS = "0xF616061894779932a94C02447FE69C05A6D76e97";

    const cdpIdBytes32 = "0x0000000000000000000000000000000000000000000000000000000000001751";

    let account = accounts[0];

    before(async () => {
        monitor = await Monitor.at(MONITOR_ADDRESS);
        monitorProxy = await MonitorProxy.at("0x8b87f3fD702CA3d930a3263db99C6E9DD18Edb1A");

        registry = await ProxyRegistryInterface.at("0x64a436ae831c1672ae81f674cab8b6775df3475c");

        const proxyAddr = await registry.proxies(account);
        proxy = await DSProxy.at(proxyAddr);
       
    });

    function getAbiFunction(contract, functionName) {
        const abi = contract.toJSON().abi;
    
        return abi.find(abi => abi.name === functionName);
      }

      it('...should get CDPs ratio', async () => {
        const res = await monitor.getDaiAmount.call('0xa71937147b55Deb8a530C7229C442Fd3F31b7db2', cdpIdBytes32, web3.utils.toWei('1.50', 'ether'));

        console.log(res.toString());
      });
      
    //   it('...should subscribe the CDP for monitoring', async () => {
    //     const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(MonitorProxy, 'subscribe'),
    //      [cdpIdBytes32, web3.utils.toWei('1.80', 'ether'), web3.utils.toWei('1.92', 'ether'), web3.utils.toWei('1.90', 'ether'), web3.utils.toWei('10', 'ether'), MONITOR_ADDRESS]);

    //     try {
    //         const tx = await proxy.methods['execute(address,bytes)'](MonitorProxy.address, data, {from: account});

    //         console.log(tx);

            
    //     } catch(err) {
    //         console.log(err);
    //     }
    //   });

    //   it('...should authorize another address to be a caller', async () => {

    //     try {
    //         const tx = await monitor.addCaller(accounts[1], {from: account});

    //         console.log(tx);

    //     } catch(err) {
    //         console.log(err);
    //     }
    //   });

    //   it('...should call the repayFor method for the user', async () => {

    //     try {
    //         const tx = await monitor.repayFor(cdpIdBytes32, '1000000000000000', {from: accounts[1]});

    //         console.log(tx);

            
    //     } catch(err) {
    //         console.log(err);
    //     }
    //   }); 

    //   it('...should call the boostFor method for the user', async () => {

    //     try {
    //         const tx = await monitor.boostFor(cdpIdBytes32, {from: accounts[1]});

    //         console.log(tx);

            
    //     } catch(err) {
    //         console.log(err);
    //     }
    //   }); 


});