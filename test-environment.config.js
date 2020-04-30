// test-environment.config.js

require('dotenv').config();


module.exports = {
    accounts: {
      amount: 10, // Number of unlocked accounts
      ether: 1000, // Initial balance of unlocked accounts (in ether)
    },

    contracts: {
      type: 'truffle', // Contract abstraction to use: 'truffle' for @truffle/contract or 'web3' for web3-eth-contract
      defaultGas: 6e6, // Maximum gas for contract calls (when unspecified)

      // Options available since v0.1.2
      defaultGasPrice: 200e9, // Gas price for contract calls (when unspecified)
      artifactsDir: 'build/contracts', // Directory where contract artifacts are stored
    },

    node: { // Options passed directly to Ganache client
      gasLimit: 8e6, // Maximum gas per block
      gasPrice: 20e9, // Sets the default gas price for transactions if not otherwise specified.
      networkId: 1,
      fork: `${process.env.INFURA_ENDPOINT}`, // An url to Ethereum node to use as a source for a fork
      // unlocked_accounts: [''], // Array of addresses specifying which accounts should be unlocked.
    },
  };
