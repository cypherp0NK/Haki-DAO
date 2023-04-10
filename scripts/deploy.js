const hre = require("hardhat");

async function main() {
  const ContractFactory = await hre.ethers.getContractFactory("HakiDAO");

  const StakingContract = await ContractFactory.deploy("", "", "", "");

  await StakingContract.deployed();

  console.log(StakingContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
