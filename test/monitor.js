const DSProxy = artifacts.require("./DSProxy.sol");
const ProxyRegistryInterface = artifacts.require("./ProxyRegistryInterface.sol");
const Monitor = artifacts.require("./Monitor.sol");
const MonitorProxy = artifacts.require("./MonitorProxy.sol");


contract("Monitor", accounts => {

    let monitor, monitorProxy, registry, proxy, currRatio;

    const MONITOR_ADDRESS = "0x1379c57bD8EFa07B9D198c773413EaA0fF3190Ea";

    const cdpIdBytes32 = "0x0000000000000000000000000000000000000000000000000000000000001751";

    let account = accounts[0];

    before(async () => {
        monitor = await Monitor.at(MONITOR_ADDRESS);
        monitorProxy = await MonitorProxy.at("0xd87eCaa4E007f06E593709CC8834060e068bf285");

        registry = await ProxyRegistryInterface.at("0x64a436ae831c1672ae81f674cab8b6775df3475c");

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
         [cdpIdBytes32, web3.utils.toWei('1.85', 'ether'), web3.utils.toWei('1.92', 'ether'), web3.utils.toWei('1.90', 'ether'), web3.utils.toWei('10', 'ether'), MONITOR_ADDRESS]);

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


      it('...should call the boostFor method for the user', async () => {

        const amount = web3.utils.toWei('2', 'ether'); // 2 dai

        try {
            const tx = await monitor.boostFor(cdpIdBytes32, amount, {from: accounts[1]});

            console.log(tx);

            
        } catch(err) {
            console.log(err);
        }
      }); 

      //  it('...should call the repayFor method for the user', async () => {
      //   const amount = web3.utils.toWei('0.01', 'ether');

      //   try {
      //       const tx = await monitor.repayFor(cdpIdBytes32, amount, {from: accounts[1]});

      //       console.log(tx);

            
      //   } catch(err) {
      //       console.log(err);
      //   }
      // }); 


});