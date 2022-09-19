/* eslint-disable no-unused-vars */
/* eslint-disable no-undef */
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers");
const R = require("ramda");

const cyan = "\x1b[36m%s\x1b[0m";
const yellow = "\x1b[33m%s\x1b[0m";

const fromWei = (stringValue) => ethers.utils.formatUnits(stringValue, 18);
const toWei = (value) => ethers.utils.parseEther(value);

const displayChildsOfParent = (data) =>
  R.map((single) => single?.toString())(data);

describe("OVRLand ERC721 - TEST", async () => {
  let Marketplace, marketplace;
  let OVRToken, ovr;
  let OVRLand, land;
  let OVRContainer, container;
  let OVRMap, map;
  let Malicious, mal;
  let Malicious2, mal2;

  beforeEach(async () => {
    Marketplace = await ethers.getContractFactory("Marketplace");
    OVRToken = await ethers.getContractFactory("OVRToken");
    OVRLand = await ethers.getContractFactory("OVRLand");
    OVRContainer = await ethers.getContractFactory("OVRLandContainer");
    OVRMap = await ethers.getContractFactory("OVRLandMapping");
    Malicious = await ethers.getContractFactory("Malicious");
    Malicious2 = await ethers.getContractFactory("Malicious2");

    [
      owner, // 50 ether
      addr1, // 0
      addr2, // 0
      addr3, // 0
      addr4, // 0
      addr5, // 0
      addr6, // 0
      addr7, // 0
      addr8, // 0
      addr9, // 0
      addr10, // 0
      addr11, // 0
      addr12, // 0
      addr13, // 0
      addr14, // 0
      addr15, // 0
      addr16, // 0
      addr17, // 0
      addr18, // 1000 ether
    ] = await ethers.getSigners();
  });

  describe("Marketplace Contract", () => {
    it("Should deploy", async () => {
      mal = await Malicious.deploy();
      await mal.deployed();

      ovr = await OVRToken.deploy();
      await ovr.deployed();

      land = await OVRLand.deploy();
      await land.deployed();

      container = await OVRContainer.deploy();
      await container.deployed();

      await container.initialize(land.address, 50);

      map = await OVRMap.deploy(land.address);
      await map.deployed();

      mal2 = await Malicious2.deploy(map.address);
      await mal2.deployed();

      marketplace = await Marketplace.deploy();
      await marketplace.deployed();

      marketplace.initialize(
        ovr.address,
        land.address,
        container.address,
        500,
        owner.address,
        toWei("1"),
        addr5.address
      );
    });
    it("addr5 should approve marketplace", async () => {
      await ovr
        .connect(addr5)
        .approve(marketplace.address, BigInt(2 ** 256) - BigInt(1));
    });
    it("owner should mint lands", async () => {
      await land.batchMintLands(
        [
          owner.address,
          owner.address,
          owner.address,
          owner.address,
          owner.address,
          owner.address,
        ],
        [1, 2, 3, 4, 5, 6]
      );
    });
    it("owner should mint 1 container", async () => {
      await land.setApprovalForAll(container.address, true);
      await container.createContainer([1, 2], "BANANA");
    });
    it("owner should mint 5 map", async () => {
      await map
        .connect(owner)
        .batchSafeMint(
          [
            owner.address,
            owner.address,
            owner.address,
            owner.address,
            owner.address,
            owner.address,
          ],
          [1, 2, 3, 4, 5, 6],
          ["okok", "okok", "okok", "okok", "okok", "okok"],
          ["okok", "ok", "ok", "ok", "ok", "okok"]
        );
    });
    it("OVRMap roles", async () => {
      let role = await map.MINTER_ROLE();
      console.log("minter role:", role);
      role = await map.BURNER_ROLE();
      console.log("burner role", role);
      role = await map.URI_EDITOR_ROLE();
      console.log("uri editor role", role);
      role = await map.DEFAULT_ADMIN_ROLE();
      console.log("admin role", role);
    });
    it("addr1 should fail to place offer for land 3 ", async () => {
      await expect(
        marketplace.connect(addr1).placeOffer(land.address, 3, toWei("1"))
      ).to.be.revertedWith("You can't sell this NFT here");
    });
    it("owner should transfer 1 OVRMap to addr1", async () => {
      await map.transferFrom(owner.address, addr1.address, 1);
      await map.connect(addr1).setApprovalForAll(marketplace.address, true);
      await map.setApprovalForAll(marketplace.address, true);
    });
    it("owner should place an offer for map 1", async () => {
      await ovr.approve(marketplace.address, toWei("2345678909876543234567"));
      await marketplace.placeOffer(map.address, 1, toWei("20"));
    });
    it("addr1 should accept the offer for map 1", async () => {
      await marketplace.connect(addr1).acceptOffer(map.address, 1);
    });
    it("owner should sell map 2", async () => {
      await marketplace.sell(map.address, 2, toWei("1"));
    });

    it("addr1 should buy map 2", async () => {
      await ovr
        .connect(addr1)
        .approve(marketplace.address, toWei("23456789098765432345678"));
      console.debug(
        "\t\t\tbalance of owner before buy:",
        fromWei(await ovr.balanceOf(owner.address)) + " OVR"
      );
      console.debug(
        "\t\t\tbalance of addr1 before buy:",
        fromWei(await ovr.balanceOf(addr1.address)) + " OVR"
      );
      await marketplace.connect(addr1).buy(map.address, 2);
      console.debug(
        "\t\t\tbalance of address 1 after buy:",
        fromWei(await ovr.balanceOf(addr1.address)) + " OVR"
      );
      console.debug(
        "\t\t\tbalance of owner before buy:",
        fromWei(await ovr.balanceOf(owner.address)) + " OVR"
      );
      const ownerof = await map.ownerOf(2);
      console.debug("\t\t\taddress 1 address:", addr1.address);
      console.debug("\t\t\towner of map 2:", ownerof);
    });

    it("owner should try to sell map 3, 4, 1", async () => {
      await marketplace.sell(map.address, 1, toWei("1"));
      await marketplace.sell(map.address, 3, toWei("1"));
    });
    it("owner should try to update price map 1", async () => {
      await marketplace.updatePriceNft(map.address, 1, toWei("2"));
    });
    it("owner should try to cancel sell  map 3", async () => {
      await marketplace.cancelSell(map.address, 3);
    });
    it("set custom fees for OVRMap", async () => {
      await marketplace.changeFeeForNFT(5000, map.address);
    });
    it("addr1 should buy map 1", async () => {
      console.debug(
        "\t\t\tbalance of owner before buy:",
        fromWei(await ovr.balanceOf(owner.address)) + " OVR"
      );
      console.debug(
        "\t\t\tbalance of addr1 before buy:",
        fromWei(await ovr.balanceOf(addr1.address)) + " OVR"
      );
      await marketplace.connect(addr1).buy(map.address, 1);
      console.debug(
        "\t\t\tbalance of address 1 after buy:",
        fromWei(await ovr.balanceOf(addr1.address)) + " OVR"
      );
      console.debug(
        "\t\t\tbalance of owner before buy:",
        fromWei(await ovr.balanceOf(owner.address)) + " OVR"
      );
      const ownerof = await map.ownerOf(1);
      console.debug("\t\t\taddress 1 address:", addr1.address);
      console.debug("\t\t\towner of map 1:", ownerof);
    });
    it("owner should try to sell fake contract", async () => {
      await marketplace.sell(mal.address, 1, 10);
    });
    it("addr1 should try to buy fake contract", async () => {
      await marketplace.connect(addr1).buy(mal.address, 1);
    });
    it("owner should sell map 5", async () => {
      await marketplace.sell(map.address, 5, 4000);
    });
    it("owner should try to sell fake contract 2", async () => {
      await marketplace.sell(mal2.address, 1, 10);
    });
    it("addr1 should fail to try to buy fake contract, ReentrancyGuard: reentrant call", async () => {
      await expect(
        marketplace.connect(addr1).buy(mal2.address, 1)
      ).to.be.revertedWith("ReentrancyGuard: reentrant call");
    });
    it("owner should send ovr to addr2", async () => {
      await ovr.transfer(addr2.address, toWei("10"));
      await ovr
        .connect(addr2)
        .approve(marketplace.address, toWei("500000000000000"));
    });
    it("addr1 should make offer for map5", async () => {
      await marketplace.connect(addr1).placeOffer(map.address, 5, toWei("1.1"));
    });
    it("addr2 should make offer for map5", async () => {
      await marketplace.connect(addr2).placeOffer(map.address, 5, toWei("1.2"));
    });
    it("addr1 should make offer for map5", async () => {
      await marketplace.connect(addr1).placeOffer(map.address, 5, toWei("1.3"));
    });
    it("owner should accept offer for map5", async () => {
      await marketplace.acceptOffer(map.address, 5);
      let ownerMap = await map.ownerOf(5);
      console.log("Addr1 is owner of map 5? ", ownerMap == addr1.address);
    });
    it("addr1 should sell map5", async () => {
      await marketplace.connect(addr1).sell(map.address, 5, toWei("1"));
    });
    it("addr1 should change price map5", async () => {
      await marketplace
        .connect(addr1)
        .updatePriceNft(map.address, 5, toWei("2"));
    });
    it("addr1 should cancel sell map5", async () => {
      await marketplace.connect(addr1).cancelSell(map.address, 5);
    });
    it("owner should make offer for map5", async () => {
      let before = await ovr.balanceOf(owner.address);
      console.debug(
        "\t\t\tbalance of owner before offer:",
        fromWei(before) + " OVR"
      );
      await marketplace.placeOffer(map.address, 5, toWei("1.1"));
      let after = await ovr.balanceOf(owner.address);
      console.debug(
        "\t\t\tbalance of owner after offer:",
        fromWei(after) + " OVR"
      );

      console.debug("\t\t\the spent money? ", fromWei(before) < fromWei(after));
    });
    it("addr1 should cancel offer for map5", async () => {
      console.debug(
        "\t\t\tbalance of owner before cancel offer:",
        fromWei(await ovr.balanceOf(owner.address)) + " OVR"
      );
      await marketplace.connect(addr1).cancelOffer(map.address, 5);
      console.debug(
        "\t\t\tbalance of owner after cancel offer:",
        fromWei(await ovr.balanceOf(owner.address)) + " OVR"
      );
    });
  });
});
