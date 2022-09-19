/* eslint-disable no-undef */
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers");
const R = require("ramda");

const cyan = "\x1b[36m%s\x1b[0m";
const yellow = "\x1b[33m%s\x1b[0m";

const fromWei = (stringValue) => ethers.utils.formatUnits(stringValue, 18);
const toWei = (value) => ethers.utils.parseEther(value);

describe("OVRLandContainer", async () => {
  let OVRToken, ovr;
  let OVRLand, land;
  let OVRContainer, container;

  beforeEach(async () => {
    OVRToken = await ethers.getContractFactory("OVRToken");
    OVRLand = await ethers.getContractFactory("OVRLand");
    OVRContainer = await ethers.getContractFactory("OVRLandContainer");

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

  describe("OVRLandContainer hkhjl", () => {
    it("Should deploy", async () => {
      ovr = await OVRToken.deploy();
      await ovr.deployed();

      land = await OVRLand.deploy();
      await land.deployed();

      container = await OVRContainer.deploy();
      await container.deployed();
      await container.initialize(land.address, 50);
    });

    it("Addr1 should own lands 1,2,3,4,5,6", async () => {
      await land.mint(addr1.address, 1);
      await land.mint(addr1.address, 2);
      await land.mint(addr1.address, 3);
      await land.mint(addr1.address, 4);

      const test = await land.connect(addr1).balanceOf(addr1.address);
      const test2 = await land.connect(addr1).ownerOf(2);
      const test3 = await land.connect(addr2).balanceOf(addr2.address);

      console.debug("TESTTT", test);
      console.debug("TESTTT2", { test: test2, vez: addr1.address });
      console.debug("TESTTT3", test3);
    });

    it("owner should mint 1 container", async () => {
      await land.connect(addr1).setApprovalForAll(container.address, true);
      console.log("BEFORE");
      await container.connect(addr1).createContainer([1, 2], "Banana");
      console.log("AFTER");
    });
  });
});
