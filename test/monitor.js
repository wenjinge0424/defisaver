const DSProxy = artifacts.require("./DSProxy.sol");
const ProxyRegistryInterface = artifacts.require("./ProxyRegistryInterface.sol");
const Monitor = artifacts.require("./Monitor.sol");
const MonitorProxy = artifacts.require("./MonitorProxy.sol");
const DecenterMonitorLending = artifacts.require("./DecenterMonitorLending.sol");
const ERC20 = artifacts.require("./ERC20.sol");

contract("Monitor", accounts => {

    let monitor, monitorProxy, registry, proxy, currRatio, decenterLending, daiToken;

    const MONITOR_ADDRESS = "0x3F39f9d99cB7453cB71377C38e59057422277eD3";
    const DECENTER_MONITOR_LENDING = "0x32a5ee0d96397fab5254f6c28dc9cefa647be3fb";

    const cdpIdBytes32 = "0x0000000000000000000000000000000000000000000000000000000000001751";

    let account = accounts[0];

    before(async () => {
        monitor = await Monitor.at(MONITOR_ADDRESS);
        monitorProxy = await MonitorProxy.at("0xd87eCaa4E007f06E593709CC8834060e068bf285");

        registry = await ProxyRegistryInterface.at("0x64a436ae831c1672ae81f674cab8b6775df3475c");

        decenterLending = await DecenterMonitorLending.at(DECENTER_MONITOR_LENDING);
        
        daiToken = await ERC20.at('0x25a01a05C188DaCBCf1D61Af55D4a5B4021F7eeD');

        const proxyAddr = await registry.proxies(account);
        proxy = await DSProxy.at(proxyAddr);
       
    });

    function getAbiFunction(contract, functionName) {
        const abi = contract.toJSON().abi;
    
        return abi.find(abi => abi.name === functionName);
      }

      it('..should set the lending contract', async () => {
        try {
          await monitor.setLendingContract(DECENTER_MONITOR_LENDING);

          const amount = web3.utils.toWei('20', 'ether');

          await daiToken.approve(DECENTER_MONITOR_LENDING, web3.utils.toWei('200000000', 'ether'));

          await decenterLending.deposit(amount);

        } catch(err) {
          console.log(err);
        }
      });

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


      // it('...should call the boostFor method for the user', async () => {

      //   const amount = web3.utils.toWei('2', 'ether'); // 2 dai

      //   try {
      //       const tx = await monitor.boostFor(cdpIdBytes32, amount, {from: accounts[1]});

      //       console.log(tx);

            
      //   } catch(err) {
      //       console.log(err);
      //   }
      // }); 

       it('...should call the repayFor method for the user', async () => {
        const amount = web3.utils.toWei('0.01', 'ether');

        const borrowAmount = web3.utils.toWei('10', 'ether');

        try {
            const tx = await monitor.repayFor(cdpIdBytes32, amount, borrowAmount, {from: accounts[1]});

            console.log(tx);

            
        } catch(err) {
            console.log(err);
        }
      }); 


});