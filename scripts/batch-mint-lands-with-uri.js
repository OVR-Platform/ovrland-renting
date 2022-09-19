/* eslint-disable node/no-unsupported-features/node-builtins */
const { ethers } = require("hardhat");
const R = require("ramda");

const landsToMintJson = require("../scripts/edited_5__final_minting.json");
const contract = require("../artifacts/contracts/OVRLand.sol/OVRLand.json");

const contractAddress = "0x93C46aA4DdfD0413d95D0eF3c478982997cE9861";

function main() {
  execution().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

const execution = async () => {
  let totalMinted = 0;
  const batchSize = 50;
  let TransactionCount = 11913;

  const OVRLand = await ethers.getContractAt(contract.abi, contractAddress);

  const splittedLandsToMint = R.splitEvery(batchSize, landsToMintJson);

  console.log("BatchSize: ", batchSize);

  console.time("BATCH_MINT_WITH_URI");

  const landToFind = "631294703715157503";
  let finded = false;

  for (let i = 0; i < R.length(splittedLandsToMint); i++) {
    const onlyAddresses = R.map((single) => single.to, splittedLandsToMint[i]);
    const onlyTokenIds = R.map(
      (single) => single.tokenId,
      splittedLandsToMint[i]
    );

    const onlyUris = R.map((single) => single.uri, splittedLandsToMint[i]);

    const arrayLenght = R.length(onlyAddresses);

    if (R.includes(landToFind, onlyTokenIds) && !finded) {
      // console.debug("onlyTokenIds", onlyTokenIds);
      finded = true;
      continue;
    }

    if (!finded) {
      continue;
    }

    console.debug("Last TokenID", R.last(onlyTokenIds));

    // const signer0 = await ethers.provider.getSigner(0);
    // const nonce = await signer0.getTransactionCount();
    // console.debug("nonce", nonce);

    // const [owner] = await ethers.getSigners();
    // let transactionCount = await owner.getTransactionCount();

    // console.log("transactionCount_1", transactionCount);

    // if (TransactionCount >= transactionCount) {
    //   transactionCount++;
    // }

    // console.log("transactionCoun_2", transactionCount);

    const tx = await OVRLand.batchMintLandsWithUri(
      onlyAddresses,
      onlyTokenIds,
      onlyUris,
      {
        gasLimit: 12000000,
        gasPrice: 60000000000,
        // nonce: transactionCount,
      }
    );

    console.log("tx");

    await tx.wait();

    totalMinted += arrayLenght;

    // TransactionCount = transactionCount;

    console.timeLog("BATCH_MINT_WITH_URI");
    console.log("Current Batch Block: ", i + 1);
    console.log("Total OVRLands Minted: ", totalMinted);
    console.log("___________________________________________________");
  }

  console.log("COMPLETED");
  console.timeEnd("BATCH_MINT_WITH_URI");
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main();
