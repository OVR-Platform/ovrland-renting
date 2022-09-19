const { ethers, upgrades } = require("hardhat");

async function main() {
  // Deploying
  const token = await hre.ethers.getContractFactory("Assets3D");
  const erc1155 = await token.deploy();
  await erc1155.deployed();
  console.log("erc1155 deployed to: ", erc1155.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
