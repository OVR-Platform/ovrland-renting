/* eslint-disable no-undef */
const { expect } = require("chai");
const { ethers } = require("hardhat");

const { time } = require("@openzeppelin/test-helpers");

const displayTime = (unixTime) => {
  const date = new Date(unixTime * 1000).toLocaleString("it-IT");
  return date;
};

const displayBlockTime = async () => {
  const currentBlock = await time.latest();
  const currentBlockNumber = await time.latestBlock();

  console.debug("\t\t\tCurrent Block Number", currentBlockNumber.toString());
  console.debug("\t\t\tCurrent Block Timestamp", currentBlock.toString());
  console.debug(
    "\t\t\tCurrent Block Time",
    displayTime(Number(currentBlock.toString()))
  );
  console.debug("\t\t\t===============================");
};

const fromWei = (stringValue) => ethers.utils.formatUnits(stringValue, 18);
const toWei = (value) => ethers.utils.parseEther(value);

const month = 2592000;

describe("StakingIPFS - TEST", () => {
  let StakingIPFS, stakingIPFS, OVRToken, ovrToken;

  let currentBlock;

  beforeEach(async () => {
    OVRToken = await ethers.getContractFactory("OVRToken");
    StakingIPFS = await ethers.getContractFactory("StakingIPFS");
    [
      owner, // 50 ether
      addr1, // 0
      addr2, // 0
      addr3, // 0
      addr4, // 0
      addr5, // 0
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

  describe("Current Block", () => {
    it("Should be 0", async () => {
      currentBlock = await time.latest();
      const currentBlockNumber = await time.latestBlock();
      console.debug(
        "\t\t\tCurrent Block Number",
        currentBlockNumber.toString()
      );
      console.debug("\t\t\tCurrent Block Timestamp", currentBlock.toString());
      console.debug(
        "\t\t\tCurrent Block Time",
        displayTime(Number(currentBlock.toString()))
      );
    });
  });

  describe("StakingIPFS", () => {
    it("Should deploy staking + OVR", async () => {
      ovrToken = await OVRToken.deploy();
      await ovrToken.deployed();

      stakingIPFS = await StakingIPFS.deploy(ovrToken.address);
      await stakingIPFS.deployed();
      console.debug("\t\t\tStakingIPFS Address", stakingIPFS.address);
      console.debug("\t\t\tOVRToken Address", ovrToken.address);
    });
    it("owner should transfer 500k tokens to addr1 addr2 addr3", async () => {
      await ovrToken.transfer(addr1.address, toWei("500000"));
      await ovrToken.transfer(addr2.address, toWei("500000"));
      await ovrToken.transfer(addr3.address, toWei("500000"));
    });
    it("addresses should approve tokens", async () => {
      await ovrToken.approve(stakingIPFS.address, toWei("500000"));
      await ovrToken
        .connect(addr1)
        .approve(stakingIPFS.address, toWei("500000"));
      await ovrToken
        .connect(addr2)
        .approve(stakingIPFS.address, toWei("500000"));
      await ovrToken
        .connect(addr3)
        .approve(stakingIPFS.address, toWei("500000"));
    });
    it("owner should stake", async () => {
      const balanceBefore = await ovrToken.balanceOf(owner.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore));
      await stakingIPFS.stake();
      const balanceAfter = await ovrToken.balanceOf(owner.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter));
    });
    it("addr1 should stake", async () => {
      const balanceBefore = await ovrToken.balanceOf(addr1.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore));
      await stakingIPFS.connect(addr1).stake();
      const balanceAfter = await ovrToken.balanceOf(addr1.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter));
    });
    it("addr1 should try to withdraw, should FAIl", async () => {
      const balanceBefore = await ovrToken.balanceOf(addr1.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore));
      await expect(stakingIPFS.connect(addr1).withdraw()).to.be.revertedWith(
        "12 months lockup not yet expired"
      );
      const balanceAfter = await ovrToken.balanceOf(addr1.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter));
    });
    it("Move time forward", async () => {
      await time.increase(month * 5);
      displayBlockTime();
    });
    it("owner should withdraw, should fail", async () => {
      const balanceBefore = await ovrToken.balanceOf(owner.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore));
      await expect(stakingIPFS.withdraw()).to.be.revertedWith(
        "12 months lockup not yet expired"
      );
      const balanceAfter = await ovrToken.balanceOf(owner.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter));
    });

    it("addr2 should stake", async () => {
      const balanceBefore = await ovrToken.balanceOf(addr2.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore));
      await stakingIPFS.connect(addr2).stake();
      const balanceAfter = await ovrToken.balanceOf(addr2.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter));
    });

    it("addr2 should try to withdraw, should FAIL", async () => {
      const balanceBefore = await ovrToken.balanceOf(addr2.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore));
      await expect(stakingIPFS.connect(addr2).withdraw()).to.be.revertedWith(
        "12 months lockup not yet expired"
      );
      const balanceAfter = await ovrToken.balanceOf(addr2.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter));
    });

    it("Move time forward", async () => {
      await time.increase(month * 7);
      displayBlockTime();
    });

    it("addr1 should withdraw", async () => {
      const balanceBefore = await ovrToken.balanceOf(addr1.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore));
      await stakingIPFS.connect(addr1).withdraw();
      const balanceAfter = await ovrToken.balanceOf(addr1.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter));
    });

    it("owner should withdraw", async () => {
      const balanceBefore = await ovrToken.balanceOf(owner.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore));
      await stakingIPFS.withdraw();
      const balanceAfter = await ovrToken.balanceOf(owner.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter));
    });

    it("Move time forward", async () => {
      await time.increase(month * 12);
      displayBlockTime();
    });

    it("addr2 should withdraw", async () => {
      const balanceBefore = await ovrToken.balanceOf(addr2.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore));
      await stakingIPFS.connect(addr2).withdraw();
      const balanceAfter = await ovrToken.balanceOf(addr2.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter));
    });
  });
});
