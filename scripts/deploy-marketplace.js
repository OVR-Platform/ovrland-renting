const { ethers, upgrades } = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // POLYGON MAINNET
  const marketplace = await ethers.getContractFactory("OVRMarketplace");
  const OVRToken = "0xc9a4faafa5ec137c97947df0335e8784440f90b5";
  const OVRLand = "0x771468b89d8218d7f9b329dfbf4492320ce28b8d";
  const OVRLandContainer = "0x1a5006044d89e73919239e7dc3455cf5512cbc27";
  const fee = 500;
  const feeReceiver = "0x00000000000B186EbeF1AC9a27C7eB16687ac2A9";

  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const OVRMarketplace = await upgrades.deployProxy(
    marketplace,
    [OVRToken, OVRLand, OVRLandContainer, fee, feeReceiver],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  await OVRMarketplace.deployed();
  console.log("Proxy deployed to: ", OVRMarketplace.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
