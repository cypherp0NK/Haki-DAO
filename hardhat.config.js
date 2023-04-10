require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
const { task } = require("hardhat/config");
let secrets = require("./secrets");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    fantomtest: {
      url: "https://rpc.testnet.fantom.network",
      accounts: [secrets.key],
      chainId: 4002,
      live: false,
    },
  },
  etherscan: {
    apiKey: "5RGAU8VDNJP7P3IMRCKUXQ9KKI8Q5RMDUT", //testnet
    //apiKey: "4CFXDIBZ8ADWD123HKEMSNZYKTVVT85P27", //mainnet
  },
};
