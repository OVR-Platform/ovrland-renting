const { ethers, upgrades } = require("hardhat");

async function main() {
  const ProxyAddress = "0x7e98b560eFa48d8d04292EaF680E693F6EEfB534";
  const marketplace = await ethers.getContractFactory("OVRMarketplaceV2");

  const tokenAddress = "0x1631244689ec1fecbdd22fb5916e920dfc9b8d30";
  const OVRLandAddress = "0x93c46aa4ddfd0413d95d0ef3c478982997ce9861";
  const OVRContainer = "0x0000000000000000000000000000000000000000";
  const feeX100 = "500";
  const feeReciver = "0x0171a49e97e6f55f344408f6e6faea52e0158f10";

  const upgraded = await upgrades.upgradeProxy(
    ProxyAddress,
    marketplace,
    [tokenAddress, OVRLandAddress, OVRContainer, feeX100, feeReciver],
    {
      initializer: "initialize",
      kind: "uups",
    }
  );

  console.log("Proxy Upgraded: ", upgraded.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
