// We require the Buidler Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const bre = require("hardhat");
const { deployContract } = require("./utils/deployer");
const { start } = require('./utils/starter');
const { changeConstantInFile } = require('./utils/utils');

async function main() {
    const flashLoan = await deployContract("MCDSaverFlashLoan");
    await changeConstantInFile('./contracts/', 'MCDSaverTaker', 'MCD_SAVER_FLASH_LOAN', flashLoan.address);

    // await run('compile');

    // await deployContract("MCDSaverTaker");
}

start(main);
