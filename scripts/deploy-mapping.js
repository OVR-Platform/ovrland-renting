const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const OVRLandMapping = await hre.ethers.getContractFactory("OVRLandMapping");
  const ovrLandMapping = await OVRLandMapping.deploy();

  await ovrLandMapping.deployed();

  console.log("OVRLandMapping deployed to:", ovrLandMapping.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
