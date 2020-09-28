const Web3 = require('web3');
const Dec = require('decimal.js');

require('dotenv').config();

const AaveLoanInfo = require('../build/contracts/AaveLoanInfo.json');
const AddressProvider = require('../build/contracts/ILendingPoolAddressesProvider.json');
const LendingPool = require('../build/contracts/ILendingPool.json');
const PriceOracle = require('../build/contracts/IPriceOracleGetterAave.json');


const {
    fetchMakerAddresses,
    ETH_ADDRESS,
    wmul,
    wdiv
} = require('../test/helper.js');

const aaveLoanInfoAddr = '0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab';
const addressProvider = '0x24a42fD28C976A61Df5D00D0599C34c4f90748c8';

const makerVersion = "1.0.6";
const userAddr = '0x52b398e75eec28a97b115af39a91cbd5a31eef6e';

let aaveLoanInfo, makerAddresses, web3, lendingPoolAddressDataProvider;

const initContracts = async () => {

    makerAddresses = await fetchMakerAddresses(makerVersion);

    web3 = new Web3(new Web3.providers.HttpProvider(process.env.ALCHEMY_NODE));

    lendingPoolAddressDataProvider = new web3.eth.Contract(AddressProvider.abi, addressProvider);
};


const getLendingPoolDataProvider = async () => {
    const addr = await lendingPoolAddressDataProvider.methods.getLendingPoolDataProvider().call();

    return new web3.eth.Contract(LendingPool.abi, addr);
}

const getLendingPoolCore = async () => {
    const addr = await lendingPoolAddressDataProvider.methods.getLendingPoolCore().call();

    return new web3.eth.Contract(LendingPool.abi, addr);
}

const getPriceOracle = async () => {
    const addr = await lendingPoolAddressDataProvider.methods.getPriceOracle().call();

    return new web3.eth.Contract(PriceOracle.abi, addr);    
}

const getMaxCollateral = async (collateralAddress, user) => {
    const lendingPoolDataProvider = await getLendingPoolDataProvider();
    const lendingPoolCore = await getLendingPoolCore();
    const priceOracle = await getPriceOracle();

    const userGlobalData = await lendingPoolDataProvider.methods.calculateUserGlobalData(user).call();
    const reserveConfiguration = await lendingPoolCore.methods.getReserveConfiguration(collateralAddress).call();
    const tokenLtv = reserveConfiguration['1'];
    const collateralPrice = await priceOracle.methods.getAssetPrice(collateralAddress).call();
    const userTokenBalance = await lendingPoolCore.methods.getUserUnderlyingAssetBalance(collateralAddress, user).call();
    const userTokenBalanceEth = wmul(Dec(userTokenBalance.toString()).mul(1e10), collateralPrice.toString());

    let maxCollateralEth = Dec(userGlobalData.currentLtv).mul(userGlobalData.totalCollateralBalanceETH).sub(Dec(userGlobalData.totalBorrowBalanceETH).mul(100)).div(userGlobalData.currentLtv);

    console.log({maxCollateralEth});
    /// @dev final amount can't be higher than users token balance
    maxCollateralEth = maxCollateralEth.gt(userTokenBalanceEth) ? Dec(userTokenBalanceEth.toString()) : maxCollateralEth;

    console.log({userTokenBalance})
    console.log({userTokenBalanceEth})
    console.log({collateralPrice})

        // // might happen due to wmul precision
    if (maxCollateralEth.gte(userGlobalData.totalCollateralBalanceETH)) {
        console.log('gte');
        return totalCollateralETH;
    }


    const a = Dec(wmul(userGlobalData.currentLtv, userGlobalData.totalCollateralBalanceETH)).sub(wmul(tokenLtv, userTokenBalanceEth))
    const newLtv = wdiv(a.add(wmul(Dec(userTokenBalanceEth).sub(maxCollateralEth).toString(), tokenLtv)), Dec(userGlobalData.totalCollateralBalanceETH).sub(maxCollateralEth));

    console.log({newLtv});
    console.log({'currentLtv': userGlobalData.currentLtv});

    console.log({maxCollateralEth});
    const returnValue = Dec(wmul(wdiv(maxCollateralEth, collateralPrice), '999900000000000000')).div(1e10).toFixed(0);
    console.log({returnValue});

    return;

}

(async () => {
    await initContracts();

    await getMaxCollateral('0x2260fac5e5542a773aa44fbcfedf7c193bc2c599', '0xe20AA1584Df34B8be8D544A9Ae15eB49807d5D93');
})();