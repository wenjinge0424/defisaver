const Web3 = require('web3');

require('dotenv').config();


const abi = [ { "inputs": [ { "components": [ { "internalType": "address", "name": "srcAddr", "type": "address" }, { "internalType": "address", "name": "destAddr", "type": "address" }, { "internalType": "uint256", "name": "srcAmount", "type": "uint256" }, { "internalType": "uint256", "name": "destAmount", "type": "uint256" }, { "internalType": "uint256", "name": "minPrice", "type": "uint256" }, { "internalType": "address", "name": "wrapper", "type": "address" }, { "components": [ { "internalType": "address", "name": "exchangeAddr", "type": "address" }, { "internalType": "address", "name": "allowanceTarget", "type": "address" }, { "internalType": "uint256", "name": "price", "type": "uint256" }, { "internalType": "uint256", "name": "fee", "type": "uint256" }, { "internalType": "bytes", "name": "callData", "type": "bytes" } ], "internalType": "struct SaverExchangeData.OffchainData", "name": "offhchainData", "type": "tuple" } ], "internalType": "struct SaverExchangeData.ExchangeData", "name": "_exData", "type": "tuple" } ], "name": "packExchangeData", "outputs": [ { "internalType": "bytes", "name": "", "type": "bytes" } ], "stateMutability": "pure", "type": "function" }, { "inputs": [ { "internalType": "bytes", "name": "_data", "type": "bytes" } ], "name": "unpackExchangeData", "outputs": [ { "components": [ { "internalType": "address", "name": "srcAddr", "type": "address" }, { "internalType": "address", "name": "destAddr", "type": "address" }, { "internalType": "uint256", "name": "srcAmount", "type": "uint256" }, { "internalType": "uint256", "name": "destAmount", "type": "uint256" }, { "internalType": "uint256", "name": "minPrice", "type": "uint256" }, { "internalType": "address", "name": "wrapper", "type": "address" }, { "components": [ { "internalType": "address", "name": "exchangeAddr", "type": "address" }, { "internalType": "address", "name": "allowanceTarget", "type": "address" }, { "internalType": "uint256", "name": "price", "type": "uint256" }, { "internalType": "uint256", "name": "fee", "type": "uint256" }, { "internalType": "bytes", "name": "callData", "type": "bytes" } ], "internalType": "struct SaverExchangeData.OffchainData", "name": "offhchainData", "type": "tuple" } ], "internalType": "struct SaverExchangeData.ExchangeData", "name": "_exData", "type": "tuple" } ], "stateMutability": "pure", "type": "function" } ];

let exchangeData, web3;

const initContracts = async () => {

    web3 = new Web3(new Web3.providers.HttpProvider(process.env.KOVAN_INFURA_ENDPOINT));

    exchangeData = new web3.eth.Contract(abi, '0x71CaF103520e083E344e8BdA5D14Ae52F1B14444');
};


const packData = async (data) => {
    const packedData = await exchangeData.methods.packExchangeData(data).call();

    return packedData;
};

const unpackData = async (packedData) => {
    const data = await exchangeData.methods.unpackExchangeData(packedData).call();

    return data;    
}


(async () => {
    await initContracts();

    const addr = '0x24a42fD28C976A61Df5D00D0599C34c4f90748c8';

    const exData = [
      addr,
      addr,
      0,
      0,
      0,
      addr,
      [addr, addr, 0, 0, "0x00"]
    ];

    const packedData = await packData(exData);
    console.log(packedData);

    const unpackedData = await unpackData(packedData);
    console.log(unpackedData);
})();