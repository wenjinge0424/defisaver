const path = require("path");

const dotenv           = require('dotenv').config();
const HDWalletProvider = require('truffle-hdwallet-provider');

const mnemonic = process.env.ETHEREUM_ACCOUNT_MNEMONIC;

module.exports = {
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  networks: {
    mainnet: {
        provider: function() {
            return new HDWalletProvider(mnemonic, process.env.INFURA_ENDPOINT);
        },
        network_id: '1',
        gasPrice: 8100000000, // 8.1 gwei
        skipDryRun: true,
    },
    kovan: {
        provider: function() {
            return new HDWalletProvider(mnemonic, process.env.KOVAN_INFURA_ENDPOINT, 0, 15);
        },
        network_id: '42',
        gas: 8000000,
        gasPrice: 3000000000,
        // skipDryRun: true,
    },
  },
  compilers: {
    solc: {
      version: "0.5.7",
      settings: {
        optimizer: {
          enabled: true,
          runs: 20000
        },
      }
    }
  }
}
