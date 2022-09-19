const { ethers, upgrades } = require("hardhat");

async function main() {
  const Renting = await ethers.getContractFactory("OVRLandRenting");

  const ProxyAddress = "0x671f928505c108e49c006fb97066cfdab34a2898";

  const _tokenAddress = "0x1631244689EC1fEcbDD22fb5916E920dFC9b8D30";
  const _OVRLandAddress = "0x93C46aA4DdfD0413d95D0eF3c478982997cE9861";
  const _OVRLandExperience = "0x90ef0bf7d34d03722fc008bf33cf59719d77b97c";
  const _OVRLandHosting = "0x0000000000000000000000000000000000000000";
  const _feeReceiver = "0x776Fa19723462F6DEB9A1fb0eaA7b3d814c45123";
  const _noRentPriceLand = "150000000000000000";
  const _noRentPriceContainer = "150000000000000000";
  const _containerAddress = "0x0000000000000000000000000000000000000000";
  const _landsPrice = "4000000000000000000";
  const _containersPrice = "4000000000000000000";

  console.log("Deploying implementation(first) and ERC1967Proxy(second)...");
  const renting = await upgrades.upgradeProxy(
    ProxyAddress,
    Renting,
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
