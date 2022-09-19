const { ethers, upgrades } = require("hardhat");

async function main() {
  const StakingV3 = await ethers.getContractFactory("StakingV3");

  const tokenAddress = "0xC9A4fAafA5Ec137C97947dF0335E8784440F90B5";
  const liquidityProviderAddress = "0x00000000000B186EbeF1AC9a27C7eB16687ac2A9";
  const stakingRewardsAddress = "0x3FCC12989eb97C170C6E08E204a37357890643d3";

  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const stakingV3 = await upgrades.deployProxy(
    StakingV3,
    [tokenAddress, liquidityProviderAddress, stakingRewardsAddress],
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
