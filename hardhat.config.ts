import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import { ETHPool } from "typechain";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts")
  .addParam("ethpool", "EthPool's address")
  .setAction(async (args, hre) => {
    const accounts = await hre.ethers.getSigners();
    const ethPool: ETHPool = await hre.ethers.getContractAt(
      "ETHPool",
      args.ethpool
    );

    for (const account of accounts) {
      const staked = await ethPool.stakedBalances(account.address);
      const reward = await ethPool.getRewardAmount(account.address);
      console.log(
        `Address: ${account.address} (Staked: ${staked}, reward: ${reward})`
      );
    }
  });

task("eth-amount", "Get total amount of ETH held in the contract")
  .addParam("ethpool", "EthPool's address")
  .setAction(async (args, hre) => {
    const { ethers } = hre;
    const totalPool = await ethers.provider.getBalance(args.ethpool);
    console.log("Total ETH in Pool: ", totalPool.toString());
  });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
    kovan: {
      url: process.env.KOVAN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
