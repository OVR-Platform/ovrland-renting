const { ethers, upgrades } = require("hardhat");

async function main() {
  const OVRLandHosting = await ethers.getContractFactory("OVRLandHosting");

  const _rentingAddress = "0x31f62eAbEb4BaC625aBe9D2838D7A821776ac16f";
  const _token = "0xC9A4fAafA5Ec137C97947dF0335E8784440F90B5";
  const _OVRLandAddress = "0x0000000000000000000000000000000000000000";
  const _feeReceiver = "0x00000000000B186EbeF1AC9a27C7eB16687ac2A9";

  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const renting = await upgrades.deployProxy(
    OVRLandHosting,
    [_rentingAddress, _OVRLandAddress, _feeReceiver, _token],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );
  await renting.deployed();
  console.log("Proxy deployed to: ", renting.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
