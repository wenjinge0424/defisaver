const Web3 = require('web3');

require('dotenv').config();
const { loadAccounts, getAccounts, fundIfNeeded } = require('../test/helper.js');
const { time } = require('@openzeppelin/test-helpers');

// configs
const gasPrice = 9200000000;

// TODO: Change for mainnet
const subscriptionsContractAddress = '0x5b1869D9A4C187F2EAa108f3062412ecf0526b24';

const MCDMonitorProxy = require("../build/contracts/MCDMonitorProxy.json");
const Subscriptions = require("../build/contracts/Subscriptions.json");
const SubscriptionsMigrations = require("../build/contracts/SubscriptionsMigration.json");

function chunk (arr, len) {

  var chunks = [],
      i = 0,
      n = arr.length;

  while (i < n) {
    chunks.push(arr.slice(i, i += len));
  }

  return chunks;
}

function removeZeroElements(arr) {
    var i = arr.length;
    while (i--) {
        if (arr[i].cdpId === '0') {
            arr.splice(i, 1);
        }
    }
    return arr;
}

const initContracts = async () => {
    // TODO: change to mainnet
    web3 = new Web3(new Web3.providers.HttpProvider(process.env.MOON_NET_NODE));
    web3 = loadAccounts(web3);
    accounts = getAccounts(web3);

    makerAddresses = await fetchMakerAddresses(makerVersion);

    bot = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY_BOT)
    web3.eth.accounts.wallet.add(bot)

    owner = web3.eth.accounts.privateKeyToAccount('0x'+process.env.PRIV_KEY_OWNER)
    web3.eth.accounts.wallet.add(owner)

    // fund all addresses
    await fundIfNeeded(web3, accounts[0], bot.address);
    await fundIfNeeded(web3, accounts[0], owner.address);

    // ----------------------------- automatic specific -----------------------------

    subscriptionsContract = new web3.eth.Contract(Subscriptions.abi, '0x83152CAA0d344a2Fd428769529e2d490A88f4393');
    monitorProxy = new web3.eth.Contract(MCDMonitorProxy.abi, '0x93Efcf86b6a7a33aE961A7Ec6C741F49bce11DA7');
    subscriptionsMigrations = new web3.eth.Contract(SubscriptionsMigrations.abi, subscriptionsContractAddress);
};

const startChangeMonitor = async () => {
  console.log('Start monitor change');
  await monitorProxy.methods.changeMonitor(subscriptionsContractAddress).send({from: bot.address, gas: 250000, gasPrice: gasPrice});
};

const confirmMonitorChangeAndAuthorizeBot = async () => {
  await monitorProxy.methods.confirmNewMonitor().send({from: bot.address, gas: 250000, gasPrice: gasPrice});
  console.log('Monitor changed');

  console.log('Authorize bot');
  // TODO: change sender to owner
  await subscriptionsMigrations.methods.setAuthorized(bot.address, true).send({from: accounts[0], gas: 250000, gasPrice: gasPrice});
  console.log('Bot authorized');
}

const migrateVaults = async (subscribers) => {
  console.log('Total subscribers:', subscribers.length);
  const cdpIds = subscribers.map(sub => sub.cdpId);
  const chunks = chunk(cdpIds, 15);

  for (var i = chunks.length - 1; i >= 0; i--) {
      console.log('migrating:', chunks[i]);
      await subscriptionsMigrations.methods.migrate(chunks[i]).send({from: bot.address, gas: 4000000, gasPrice: gasPrice});
  }

  console.log("Subscriptions migrated")
}

const removeAuthorities = async (addresses) => {
  console.log('Total addresses:', addresses.length);
  const chunks1 = chunk(addresses, 15);

  for (var i = chunks1.length-1; i >= 0; i--) {
      console.log(chunks1[i])
      await subscriptionsMigrations.methods.removeAuthority(chunks1[i]).send({from: bot.address, gas: 4000000}, gasPrice: gasPrice);
  }

  console.log('Authorities removed'); 
}

const unsubscribeMoved = async (subscribers) => {
  for (var i = subscribers.length-1; i >= 0; i--) {
      await subscriptionsContract.methods.unsubscribeIfMoved(subscribers[i].cdpId).send({from: bot.address, gas: 500000, gasPrice: gasPrice});
  }

  console.log('Removed moved subscribers');

  const finalSubscribers = await subscriptionsContract.methods.getSubscribers().call();
  console.log('Final count:', removeZeroElements(finalSubscribers.length));
}

(async () => {
    await initContracts();

    // FIRST PART
    // -----------------------------------------------------------------
    await startChangeMonitor();

    // SECOND PART
    // -----------------------------------------------------------------
    // forward time for two weeks 
    // TODO: remove for mainnet
    await time.increase(60*60*24*15);  

    await confirmMonitorChangeAndAuthorizeBot();
    const subscribersAll = await subscriptionsContract.methods.getSubscribers().call();

    await migrateVaults(removeZeroElements(subscribersAll));

    // should be changed to all addresses that ever had authority
    const allAddresses = subscribersAll.map(sub => sub.owner);
    await removeAuthorities(allAddresses);

    const leftSubscribers = await subscriptionsContract.methods.getSubscribers().call();
    await unsubscribeMoved(removeZeroElements(leftSubscribers));
})();