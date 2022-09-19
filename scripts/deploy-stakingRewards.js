const { ethers, upgrades } = require("hardhat");

async function main() {
  const StakingRewards = await ethers.getContractFactory("StakingRewards");

  const tokenAddress = "0xC9A4fAafA5Ec137C97947dF0335E8784440F90B5";

  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const stakingRewards = await upgrades.deployProxy(
    StakingRewards,
    [tokenAddress],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  await stakingRewards.deployed();
  console.log("Proxy deployed to: ", stakingRewards.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
