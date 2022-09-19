const { ethers } = require("hardhat");
const R = require("ramda");

const formatEthers = (stringValue) => ethers.utils.formatUnits(stringValue, 18);
const formatWei = (stringValue) =>
  ethers.utils.parseUnits(stringValue, "ether");

const holdersETH = require("../scripts/holders_eth.json");
const holdersPolygon = require("../scripts/holders_poly.json");

function main() {
  execution().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

const execution = async () => {
  const provider = await ethers.provider;

  const [signer] = await ethers.getSigners();

  const balance = await provider.getBalance(signer.address);
  console.debug("Balance", formatEthers(balance));

  console.debug("Count holdersETH", R.length(holdersETH));
  console.debug("Count holdersPoly", R.length(holdersPolygon));
  console.debug("Union", R.length(R.concat(holdersETH, holdersPolygon)));

  console.debug("Uniq", R.length(R.uniq(R.concat(holdersETH, holdersPolygon))));
  const finalList = R.uniq(R.concat(holdersETH, holdersPolygon));

  // for (let i = 0; i < holdersSize; i++) {
  //   const tx = {
  //     from: signer.address,
  //     to: holders[i],
  //     value: formatWei("0.0625"), // $ 0.1
  //     gasLimit: 21000,
  //     gasPrice: 50000000000,
  //   };

  //   await signer.sendTransaction(tx);
  // }
};

main();
