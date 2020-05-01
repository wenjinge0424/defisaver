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

    setupProvider: (baseProvider) => {
        baseProvider.host = `${process.env.MOON_NET_KEY}`;

        return baseProvider;
      },
  };
