// We require the Buidler Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const bre = require("hardhat");
const { deployContract } = require("./utils/deployer");
const { start } = require('./utils/starter');
const { changeConstantInFile } = require('./utils/utils');

async function main() {
    // await deployContract("MCDCloseFlashLoan");
    // await deployContract("MCDCloseTaker");

    // const flashLoan = await deployContract("MCDSaverFlashLoan");
    // await changeConstantInFile('./contracts/', 'MCDSaverTaker', 'MCD_SAVER_FLASH_LOAN', flashLoan.address);

    // const mcdCreateFlashLoan = await deployContract("MCDCreateFlashLoan");
    // await changeConstantInFile('./contracts/', 'MCDCreateTaker', 'MCD_CREATE_FLASH_LOAN', mcdCreateFlashLoan.address);

    // await run('compile');

    await deployContract("MCDSaverTaker");
    // await deployContract("MCDCreateTaker");
}

start(main);
