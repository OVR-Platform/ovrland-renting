const { ethers, upgrades } = require("hardhat");

async function main() {
  // WARNING NOTE assiucrarsi che in price calculator siano presenti gli address della mainnet
  const OVRLandRenting = await ethers.getContractFactory("OVRLandRenting");

  const _tokenAddress = "0x1631244689EC1fEcbDD22fb5916E920dFC9b8D30";
  const _OVRLandAddress = "0x93C46aA4DdfD0413d95D0eF3c478982997cE9861";
  const _OVRLandExperience = "0x0000000000000000000000000000000000000000";
  const _OVRLandHosting = "0x0000000000000000000000000000000000000000";
  const _feeReceiver = "0x776Fa19723462F6DEB9A1fb0eaA7b3d814c45123";
  const _noRentPriceLand = "150000000000000000";
  const _noRentPriceContainer = "150000000000000000";
  const _containerAddress = "0x0000000000000000000000000000000000000000";
  const _landsPrice = "4000000000000000000";
  const _containersPrice = "4000000000000000000";

  // todo   const _feeReceiver = "0x00000000000B186EbeF1AC9a27C7eB16687ac2A9"; experience "0x0000000000000000000000000000000000000000";

  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const renting = await upgrades.deployProxy(
    OVRLandRenting,
    [
      _tokenAddress,
      _OVRLandAddress,
      _OVRLandExperience,
      _OVRLandHosting,
      _feeReceiver,
      _noRentPriceLand,
      _noRentPriceContainer,
      _containerAddress,
      _landsPrice,
      _containersPrice,
    ],
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
