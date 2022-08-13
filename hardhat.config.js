require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ALCHEMY_MAINNET_FORK_URL = process.env.ALCHEMY_MAINNET_FORK_URL;

module.exports = {
  networks: {
    hardhat: {
      hackShit: {
        url: ALCHEMY_MAINNET_FORK_URL,
        rinkeby: {
          url: RINKEBY_RPC_URL,
          accounts: [PRIVATE_KEY],
          chainId: 4,
        },
      },
    },
  },
  mocha: {
    useColors: true,
  },
  solidity: "0.8.0",
  compilers: {
    solc: {
      version: "0.8.0",
      settings: {
        optimizer: {
          enabled: true,
          runs: 999999,
        },
      },
    },
  },
};
