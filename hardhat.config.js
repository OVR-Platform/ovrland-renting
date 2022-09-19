require("dotenv").config();
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("@nomiclabs/hardhat-web3");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },

      {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.6.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.6.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      },
    },
    testnet: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      accounts: [process.env.PRIVATE_KEY],
    },
    "matic-mainnet": {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      // url: "https://speedy-nodes-nyc.moralis.io/1b731ea0a7f7b220fa30ed97/polygon/mainnet",
      // url: "https://speedy-nodes-nyc.moralis.io/1b731ea0a7f7b220fa30ed97/polygon/mainnet",
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 75000000000,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    enabled: process.env.COINMARKETCAP_API_KEY !== undefined,
    url: "https://polygon-rpc.com",
    token: "MATIC",
    gasPriceApi:
      "https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice",
  },
};
