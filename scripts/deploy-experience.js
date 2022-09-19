const { ethers, upgrades } = require("hardhat");

async function main() {
  const _OVRLandAddress = "0x93C46aA4DdfD0413d95D0eF3c478982997cE9861";
  const _OVRLandRenting = "0x671F928505C108E49c006fb97066CFdAB34a2898";
  const _OVRContainer = "0x0000000000000000000000000000000000000000";

  const Experience = await ethers.getContractFactory("OVRLandExperience");
  const experience = await upgrades.deployProxy(
    Experience,
    [_OVRLandAddress, _OVRLandRenting, _OVRContainer],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );

  await experience.deployed();

  console.log("experience deployed to:", experience.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
