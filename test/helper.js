
const loadAccounts = (web3) => {
    const account = web3.eth.accounts.privateKeyToAccount('0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d')
    web3.eth.accounts.wallet.add(account);

    return web3;
};

const getAccounts = (web3) => {
    const walletes = Object.values(web3.eth.accounts.wallet);

    return walletes.map(w => w.address);
};


const getAbiFunction = (contract, functionName) => {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
};


module.exports = {
    getAbiFunction,
    loadAccounts,
    getAccounts,
};
