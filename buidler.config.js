usePlugin("@nomiclabs/buidler-etherscan");
usePlugin("buidler-ethers-v5");
usePlugin("@nomiclabs/buidler-solhint");

const dotenv           = require('dotenv').config();

module.exports = {
    networks: {
        buidlerevm: {
        },
        moonnet: {
            url: process.env.MOON_NET_NODE,
            accounts: [process.env.PRIV_KEY_DEV],
            gasPrice: 1000000000
        },
        mainnet: {
            url: process.env.ALCHEMY_NODE,
            accounts: [process.env.PRIV_KEY_OWNER],
            gasPrice: 60000000000
        },
        kovan: {
            url: process.env.KOVAN_INFURA_ENDPOINT,
            accounts: [process.env.PRIV_KEY_KOVAN],
            gasPrice: 1600000000
        },
        dev: {
            url: 'http://127.0.0.1:8545',
            accounts: [process.env.LOCAL_PK],
            gasPrice: 70000000000
        }
    },
    solc: {
        version: "0.6.6",
        optimizer: {
            enabled: true,
            runs: 200
        }
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY
    }
};
