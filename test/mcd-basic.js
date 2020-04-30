
// const DSProxy = artifacts.require("./DSProxy.sol");
// const ProxyRegistryInterface = artifacts.require("./ProxyRegistryInterface.sol");
// const ERC20 = artifacts.require("./ERC20.sol");
// const Join = artifacts.require("./Join.sol");
// const DSSProxyActions = artifacts.require("./DSSProxyActions.sol");
// const GetCdps = artifacts.require('./GetCdps.sol');

// contract("MCDBasic", accounts => {

//     let account = accounts[0];
//     let registry, proxy, join, getCdps;

//     const proxyRegistryAddr = '0x64a436ae831c1672ae81f674cab8b6775df3475c';
//     const proxyActionsAddr = '0xc21274797a01e133ebd9d79b23498edbd7166137';
//     const cdpManagerAddr = '0x1cb0d969643af4e929b3fafa5ba82950e31316b8';
//     const ethAJoinAddr = '0xc3abba566bb62c09b7f94704d8dfd9800935d3f9';
//     const getCdpsAddr = '0xb5907a51e3b747dbf9d5125ab77eff3a55e50b7d';

//     const ethIlk = '0x4554482d41000000000000000000000000000000000000000000000000000000';

//     function getAbiFunction(contract, functionName) {
//         const abi = contract.toJSON().abi;

//         return abi.find(abi => abi.name === functionName);
//     }

//     before(async () => {
//         registry = await ProxyRegistryInterface.at(proxyRegistryAddr);

//         const proxyAddr = await registry.proxies(account);
//         proxy = await DSProxy.at(proxyAddr);

//         join = await Join.at(ethAJoinAddr);
//         getCdps = await GetCdps.at(getCdpsAddr);

//     });

//     // it('...get info', async () => {

//     //     console.log(join.methods);
//     //     const ilk = await join.ilk.call();

//     //     console.log(ilk.toString());
//     // });

//     it('... reads all the CDPs', async () => {
//         const cdps = await getCdps.getCdpsAsc.call(cdpManagerAddr, proxyAddr);

//         console.log(cdps);
//     });

//     it('...open a mCDP', async () => {
//         const data = web3.eth.abi.encodeFunctionCall(getAbiFunction(DSSProxyActions, 'open'),
//          [cdpManagerAddr, ethIlk]);

//          try {
//             const tx = await proxy.methods['execute(address,bytes)'](proxyActionsAddr, data, {from: account});
//             console.log(tx);
//          } catch(err) {
//              console.log(err);
//          }
//     });


// });
