const { ethers, upgrades } = require("hardhat");

async function main() {
  const StakingRewards = await ethers.getContractFactory("StakingRewards");

  const tokenAddress = "0xC9A4fAafA5Ec137C97947dF0335E8784440F90B5";

  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const stakingV3 = await upgrades.upgradeProxy(
    "0x3fcc12989eb97c170c6e08e204a37357890643d3",
    StakingRewards,
    [tokenAddress],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  await stakingV3.deployed();
  console.log("Proxy deployed to: ", stakingV3.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
