

const getAbiFunction = (contract, functionName) => {
    const abi = contract.abi;

    return abi.find(abi => abi.name === functionName);
}


module.exports = {
    getAbiFunction,
};
