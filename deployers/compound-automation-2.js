// We require the Buidler Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const { deployContract } = require("./utils/deployer");
const { start } = require('./utils/starter');

async function main() {
  const compoundMonitorProxyAddress = '0xB1cF8DE8e791E4Ed1Bd86c03E2fc1f14389Cb10a';
  const subscriptionsAddress = '0x52015EFFD577E08f498a0CCc11905925D58D6207';
  const compoundFlashLoanTakerAddress = '0x602613C7fa3b0c0B6DD4977E16DD5F00d00648f2';

  await deployContract("CompoundMonitor", compoundMonitorProxyAddress, subscriptionsAddress, compoundFlashLoanTakerAddress);
}

start(main);