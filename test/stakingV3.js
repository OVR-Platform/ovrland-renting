/* eslint-disable no-unused-vars */
/* eslint-disable no-undef */
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

const { time } = require("@openzeppelin/test-helpers");

// suppose the current block has a timestamp of 01:00 PM
// await network.provider.send("evm_increaseTime", [3600])
// await network.provider.send("evm_mine") // this one will have 02:00 PM as its timestamp

const displayTime = (unixTime) => {
  const date = new Date(unixTime * 1000).toLocaleString("it-IT");
  return date;
};

const fromWei = (stringValue) => ethers.utils.formatUnits(stringValue, 18);
const toWei = (value) => ethers.utils.parseEther(value);

const month = 2592000;
const day = 86400;

describe("StakingV3 - TEST", () => {
  let StakingV3,
    stakingV3,
    OVRToken,
    ovrToken,
    owner,
    StakingRewards,
    stakingReward;
  let ovrTokenAddress, stakingV3Address;
  const provider = ethers.getDefaultProvider();

  let initialTotalSupply;
  let currentBlock;

  beforeEach(async () => {
    OVRToken = await ethers.getContractFactory("OVRToken");
    StakingRewards = await ethers.getContractFactory("StakingRewards");
    StakingV3 = await ethers.getContractFactory("StakingV3");
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
      console.debug(
        "\t\t\tCurrent Block Time",
        displayTime(Number(currentBlock.toString()))
      );
    });
  });

  describe("OVR Token Contract", () => {
    it("Should deploy", async () => {
      ovrToken = await OVRToken.deploy();
      await ovrToken.deployed();

      ovrTokenAddress = ovrToken.address;
      console.debug("\t\t\tOVR Token Contract Address:", ovrTokenAddress);

      const balance = await provider.getBalance(owner.address);
      console.debug("\n\t\t\tOWNER", owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());

      const ownerOVRBalance = await ovrToken.balanceOf(owner.address);

      const balanceOwner = ethers.utils.formatEther(ownerOVRBalance);
      console.debug("\t\t\tOWNER OVR Balance:", `${balanceOwner.toString()}`);

      initialTotalSupply = await ovrToken.totalSupply();
      console.debug(
        "\t\t\tInitial Total Supply:",
        `${initialTotalSupply.toString()}`
      );
    });
  });

  describe("StakingRewards Contract", () => {
    it("Should deploy", async () => {
      stakingReward = await upgrades.deployProxy(
        StakingRewards,
        [ovrToken.address],
        {
          initializer: "initialize",
          kind: "uups",
        }
      );

      await stakingReward.deployed();
    });
  });

  describe("StakingV3 Contract", () => {
    it("Should deploy", async () => {
      stakingV3 = await upgrades.deployProxy(
        StakingV3,
        [ovrToken.address, addr18.address, stakingReward.address],
        {
          initializer: "initialize",
          kind: "uups",
        }
      );
      await stakingV3.deployed();
      stakingV3Address = stakingV3.address;
      console.debug("\t\t\tContract Address: ", stakingV3Address);
      await ovrToken.approve(stakingV3Address, toWei("10000000"));
    });
  });

  describe("OVR Token Approve", () => {
    it("Should test 'approve' and 'allowance' from the owner to first Comer", async function () {
      const amountForApproval = toWei("10000000");
      await ovrToken.approve(stakingV3Address, amountForApproval);
      const allowance = await ovrToken.allowance(
        owner.address,
        stakingV3Address
      );
      expect(allowance.toString()).to.equal(amountForApproval.toString());
    });
  });

  describe("StakingV3 Fist Check", () => {
    it("Set Liquidity Provider Allowance (owner) ", async () => {
      await ovrToken
        .connect(owner)
        .approve(stakingV3Address, "100000000000000000000000");
      const allowance = await ovrToken
        .connect(owner)
        .allowance(owner.address, stakingV3Address);
      expect(allowance.toString()).to.equal("100000000000000000000000");
    });
  });

  describe("Transactions", () => {
    it("Addr1 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr1.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr1.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });
    it("Addr1 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr18.address, toWei("10000000000"));
      await ovrToken
        .connect(addr18)
        .approve(stakingV3Address, toWei("10000000000"));
    });

    it("Addr2 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr2.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr2.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Addr3 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr3.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr3.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Addr4 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr4.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr4.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Addr5 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr5.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr5.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Addr6 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr6.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr6.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Addr7 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr7.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr7.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Addr8 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr8.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr8.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Addr9 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr9.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr9.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Addr10 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr10.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr10.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Addr11 should own 1000 OVR", async () => {
      await ovrToken
        .connect(owner)
        .transfer(addr11.address, "1000000000000000000000");
      const addrOVRBalance = await ovrToken.balanceOf(addr11.address);
      expect(addrOVRBalance.toString()).to.equal("1000000000000000000000");
    });

    it("Owner should own (totalSupply - 10,000 OVR)", async () => {
      const ownerOVRBalance = await ovrToken.balanceOf(owner.address);

      const totalSupply = initialTotalSupply
        .sub("1000000000000000000000")
        .sub("1000000000000000000000")
        .sub("1000000000000000000000")
        .sub("1000000000000000000000")
        .sub("1000000000000000000000")
        .sub("1000000000000000000000")
        .sub("1000000000000000000000")
        .sub("1000000000000000000000")
        .sub("1000000000000000000000")
        .sub("1000000000000000000000")
        .sub("1000000000000000000000");

      console.debug("\n\tOWNER BALANCE   :", ownerOVRBalance.toString());
      console.debug("\tTOTAL TRANSFERS :", Number(1000 * 10).toString());
      console.debug("\tTOTAL SUPPLY    :", totalSupply.toString());
      console.debug("\t");

      // expect(ownerOVRBalance.toString()).to.equal(totalSupply.toString());
    });
  });

  describe("OVR Allowance", () => {
    it("Staking Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr1)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr1)
        .allowance(addr1.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr1 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr1)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr1)
        .allowance(addr1.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr2 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr2)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr2)
        .allowance(addr2.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr3 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr3)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr3)
        .allowance(addr3.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr4 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr4)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr4)
        .allowance(addr4.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr5 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr5)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr5)
        .allowance(addr5.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr6 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr6)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr6)
        .allowance(addr6.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr7 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr7)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr7)
        .allowance(addr7.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr8 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr8)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr8)
        .allowance(addr8.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr9 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr9)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr9)
        .allowance(addr9.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr10 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr10)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr10)
        .allowance(addr10.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });

    it("Addr11 Completed Allowance 10000 OVR", async () => {
      await ovrToken
        .connect(addr11)
        .approve(stakingV3Address, "10000000000000000000000");
      const allowance = await ovrToken
        .connect(addr11)
        .allowance(addr11.address, stakingV3Address);
      expect(allowance.toString()).to.equal("10000000000000000000000");
    });
  });

  describe("Deposits", () => {
    it("Addr1 should have deposited 300 OVR with 3 Months Lockup", async () => {
      const balance = await ovrToken.balanceOf(stakingV3.address);
      console.debug(
        "\t\t\tCurrent StakingContract Balance",
        fromWei(balance.toString())
      );

      const depositAmount = "300000000000000000000";
      const depositId = 2;
      const address = addr1.address;
      // Deposit
      console.log("before deposit");
      await stakingV3.connect(addr1).deposit(depositId, depositAmount);
      console.log("deposited");
      const addr1StakingBalance = await stakingV3.balanceOf(depositId, address);

      console.log(
        "\tbalances[addr1][1]:",
        ethers.utils.formatEther(addr1StakingBalance.toString())
      );
      expect(depositAmount.toString()).to.equal(addr1StakingBalance.toString());
    });

    it("Addr2 should have deposited 400 OVR with 6 Months Lockup", async () => {
      const depositAmount = "400000000000000000000";
      const depositId = 3;
      const address = addr2.address;
      // Deposit
      await stakingV3.connect(addr2).deposit(depositId, depositAmount);

      const addr1StakingBalance = await stakingV3.balanceOf(depositId, address);

      console.log(
        "\tbalances[addr2][2]:",
        ethers.utils.formatEther(addr1StakingBalance.toString())
      );
      expect(depositAmount.toString()).to.equal(addr1StakingBalance.toString());
    });

    it("Addr3 should have deposited 500 OVR with 6 Months Lockup", async () => {
      const depositAmount = "500000000000000000000";
      const depositId = 3;
      const address = addr3.address;
      // Deposit
      await stakingV3.connect(addr3).deposit(depositId, depositAmount);

      const addr1StakingBalance = await stakingV3.balanceOf(depositId, address);

      console.log(
        "\tbalances[addr3][3]:",
        ethers.utils.formatEther(addr1StakingBalance.toString())
      );
      expect(depositAmount.toString()).to.equal(addr1StakingBalance.toString());
    });

    it("Addr4 should have deposited 300 OVR with 12 Months Lockup", async () => {
      const depositAmount = "300000000000000000000";
      const depositId = 5;
      const address = addr4.address;
      // Deposit
      await stakingV3.connect(addr4).deposit(depositId, depositAmount);

      const addr1StakingBalance = await stakingV3.balanceOf(depositId, address);

      console.log(
        "\tbalances[addr4][4]:",
        ethers.utils.formatEther(addr1StakingBalance.toString())
      );
      expect(depositAmount.toString()).to.equal(addr1StakingBalance.toString());
    });

    it("Addr5 should have deposited 500 OVR with 9 Months Lockup", async () => {
      const depositAmount = "500000000000000000000";
      const depositId = 4;
      const address = addr5.address;
      // Deposit
      await stakingV3.connect(addr5).deposit(depositId, depositAmount);

      const addr1StakingBalance = await stakingV3.balanceOf(depositId, address);

      console.log(
        "\tbalances[addr5][5]:",
        ethers.utils.formatEther(addr1StakingBalance.toString())
      );
      expect(depositAmount.toString()).to.equal(addr1StakingBalance.toString());
    });

    it("Should deploy", async () => {
      stakingReward = await upgrades.upgradeProxy(
        stakingReward.address,
        StakingRewards,
        [ovrToken.address],
        {
          initializer: "initialize",
          kind: "uups",
        }
      );

      await stakingReward.deployed();
    });

    it("Addr6 should have deposited 300 OVR with No Lockup", async () => {
      const depositAmount = "300000000000000000000";
      const depositId = 1;
      const address = addr6.address;
      // Deposit
      await stakingV3.connect(addr6).deposit(depositId, depositAmount);

      const addr1StakingBalance = await stakingV3.balanceOf(depositId, address);

      console.log(
        "\tbalances[addr6][5]:",
        ethers.utils.formatEther(addr1StakingBalance.toString())
      );
      expect(depositAmount.toString()).to.equal(addr1StakingBalance.toString());
    });
  });

  describe("Passing time........ 2 Months", () => {
    it("It should be 2 months since the start", async () => {
      currentBlock = await time.latest();

      await time.increase(month * 2);

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

  describe("Withdrawal Checks", () => {
    it("Should FAIL withdraw Addr1", async () => {
      const depositId = 2;
      await expect(
        stakingV3.connect(addr1).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should FAIL withdraw Addr2", async () => {
      const depositId = 3;
      await expect(
        stakingV3.connect(addr2).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should FAIL withdraw Addr3", async () => {
      const depositId = 3;
      await expect(
        stakingV3.connect(addr3).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should FAIL withdraw Addr4", async () => {
      const depositId = 5;
      await expect(
        stakingV3.connect(addr4).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should FAIL withdraw Addr5", async () => {
      const depositId = 4;
      await expect(
        stakingV3.connect(addr5).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should PASS withdraw Addr6", async () => {
      const depositId = 1;
      await stakingV3.connect(addr6).withdrawAll(depositId);
    });
  });

  describe("Extend Lockups Checks", () => {
    it("Should PASS lockup extension Addr1", async () => {
      const depositId = 2;
      await stakingV3.connect(addr1).extendLockup(depositId);
    });

    it("Should PASS lockup extension Addr2", async () => {
      const depositId = 3;
      await stakingV3.connect(addr2).extendLockup(depositId);
    });

    it("Should PASS lockup extension Addr3", async () => {
      const depositId = 3;
      await stakingV3.connect(addr3).extendLockup(depositId);
    });

    it("Should PASS lockup extension Addr4", async () => {
      const depositId = 5;
      await stakingV3.connect(addr4).extendLockup(depositId);
    });

    it("Should PASS lockup extension Addr5", async () => {
      const depositId = 4;
      await stakingV3.connect(addr5).extendLockup(depositId);
    });

    it("Should FAIL lockup extension Addr6", async () => {
      const depositId = 2;
      await expect(
        stakingV3.connect(addr6).extendLockup(depositId)
      ).to.be.revertedWith("Your deposit is zero");
    });
  });

  describe("Passing time........ 4 Months", () => {
    it("It should be 4 months since the start", async () => {
      currentBlock = await time.latest();

      await time.increase(month * 2);

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

  describe("After 4 Months tests", () => {
    it("Should PASS lockup extension Addr1", async () => {
      const depositId = 2;
      await stakingV3.connect(addr1).extendLockup(depositId);
    });

    it("Should PASS lockup extension Addr2", async () => {
      const depositId = 3;
      await stakingV3.connect(addr2).extendLockup(depositId);
    });

    it("Should PASS lockup extension Addr3", async () => {
      const depositId = 3;
      await stakingV3.connect(addr3).extendLockup(depositId);
    });

    it("Should PASS lockup extension Addr4", async () => {
      const depositId = 5;
      await stakingV3.connect(addr4).extendLockup(depositId);
    });

    it("Should PASS lockup extension Addr5", async () => {
      const depositId = 4;
      await stakingV3.connect(addr5).extendLockup(depositId);
    });

    it("Should FAIL lockup extension Addr6", async () => {
      const depositId = 2;
      await expect(
        stakingV3.connect(addr6).extendLockup(depositId)
      ).to.be.revertedWith("Your deposit is zero");
    });
  });

  describe("Passing time........ 8 Months", () => {
    it("It should be 8 months since the start", async () => {
      currentBlock = await time.latest();

      await time.increase(month * 4);

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

  describe("After 8 Months tests", () => {
    it("Should PASS withdraw Addr1", async () => {
      const depositId = 2;
      await stakingV3.connect(addr1).withdrawAll(depositId);
    });

    it("Should FAIL withdraw Addr2", async () => {
      const depositId = 3;
      await expect(
        stakingV3.connect(addr2).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should PASS lockup extension Addr3", async () => {
      const depositId = 3;
      await stakingV3.connect(addr3).extendLockup(depositId);
    });

    it("Should FAIL withdraw Addr4", async () => {
      const depositId = 5;
      await expect(
        stakingV3.connect(addr4).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should FAIL withdraw Addr5", async () => {
      const depositId = 4;
      await expect(
        stakingV3.connect(addr5).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should PASS deposit 500 OVR Addr6", async () => {
      const depositId = 2;
      await stakingV3.connect(addr6).deposit(depositId, toWei("500"));
    });
  });

  describe("Passing time........ 10 Months", () => {
    it("It should be 10 months since the start", async () => {
      currentBlock = await time.latest();

      await time.increase(month * 2);

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

  describe("After 10 Months tests", () => {
    it("Should PASS deposit 500 OVR Addr1", async () => {
      const depositId = 2;
      await stakingV3.connect(addr1).deposit(depositId, toWei("500"));
    });

    it("Should DEPOSIT 400 OVR Addr2", async () => {
      // addr2 balance before
      const balanceBefore = await ovrToken.balanceOf(addr2.address);
      console.debug("\t\t\tBalance Before", fromWei(balanceBefore.toString()));

      const depositId = 1;
      await stakingV3.connect(addr2).deposit(depositId, toWei("400"));
      // addr2 balance after
      const balanceAfter = await ovrToken.balanceOf(addr2.address);
      console.debug("\t\t\tBalance After", fromWei(balanceAfter.toString()));
    });

    it("Should PASS lockup extension Addr3", async () => {
      const depositId = 3;
      await stakingV3.connect(addr3).extendLockup(depositId);
    });

    it("Should FAIL withdraw Addr4", async () => {
      const depositId = 5;
      await expect(
        stakingV3.connect(addr4).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should FAIL withdraw Addr5", async () => {
      const depositId = 4;
      await expect(
        stakingV3.connect(addr5).withdrawAll(depositId)
      ).to.be.revertedWith("Too early, Lockup period");
    });

    it("Should PASS deposit 400 OVR Addr6", async () => {
      const depositId = 2;
      await stakingV3
        .connect(addr6)
        .deposit(depositId, "400000000000000000000");
    });
  });

  describe("Passing time........ 13 Months", () => {
    it("It should be 13 months since the start", async () => {
      currentBlock = await time.latest();

      await time.increase(month * 3);

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

  describe("After 13 Months tests", () => {
    it("Should PASS lockup extension Addr1", async () => {
      const depositId = 2;
      await stakingV3.connect(addr1).extendLockup(depositId);
    });

    it("Should PASS deposit 500 OVR Addr2", async () => {
      const depositId = 1;
      // Insufficient budget
      await expect(
        stakingV3.connect(addr2).deposit(depositId, "500000000000000000000")
      ).to.be.reverted;
    });

    it("Should PASS lockup extension Addr3", async () => {
      const depositId = 3;
      await stakingV3.connect(addr3).extendLockup(depositId);
    });

    it("Should FAIL withdraw Addr4", async () => {
      const depositId = 5;
      await expect(
        stakingV3.connect(addr4).withdrawAll(depositId)
      ).to.be.revertedWith("'Too early, Lockup period");
    });

    it("Should PASS withdraw Addr5", async () => {
      const depositId = 4;
      await stakingV3.connect(addr5).withdrawAll(depositId);
    });

    it("Should PASS withdraw Addr6", async () => {
      const depositId = 2;
      // Insuffient Balance
      await stakingV3.connect(addr6).withdrawAll(depositId);
    });
  });

  describe("Passing time........ 19 Months", () => {
    it("It should be 19 months since the start", async () => {
      currentBlock = await time.latest();

      await time.increase(month * 6);

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

  describe("After 19 Months tests", () => {
    it("Should PASS withdraw Addr4", async () => {
      const depositId = 5;
      await stakingV3.connect(addr4).withdrawAll(depositId);
    });
    it("current staking balance:", async () => {
      const balance = await ovrToken.balanceOf(stakingV3.address);
      console.debug(
        "\t\t\tCurrent StakingContract Balance",
        fromWei(balance.toString())
      );
    });
    it("Should pass deposit addr8", async () => {
      const balanceBefore = await ovrToken.balanceOf(addr8.address);
      console.debug(
        "\t\t\tBalance Before Deposit",
        fromWei(balanceBefore.toString())
      );
      const depositId = 5;
      await stakingV3.connect(addr8).deposit(depositId, toWei("500"));
      console.debug("\t\t\tDeposited amount 500");
      const balanceAfter = await ovrToken.balanceOf(addr8.address);
      console.debug(
        "\t\t\tBalance After Deposit",
        fromWei(balanceAfter.toString())
      );
      expect(parseFloat(fromWei(balanceBefore.toString()))).to.equal(
        parseFloat(fromWei(balanceAfter.toString())) + 500.0
      );
    });
    it("It should be 5 months since the start", async () => {
      currentBlock = await time.latest();

      await time.increase(month * 5);

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
    it("addr8 should try to withdraw rewards", async () => {
      const depositId = 5;

      // CHECK REWARDS USER
      const addr8rewardsBefore = await stakingReward.availableBalance(
        addr8.address
      );

      const calculatedRewards = await stakingV3.calcRewards(
        addr8.address,
        depositId
      );

      console.log(
        "\t\t\tStakingRewardsRewards User Balance Before:",
        fromWei(addr8rewardsBefore.toString())
      );

      console.log(
        "\t\t\tCalculated Rewards",
        fromWei(calculatedRewards.toString())
      );

      // RUN TRANSACTION
      await stakingV3.connect(addr8).withdrawRewards(depositId);

      const addr8rewardsAfter = await stakingReward.availableBalance(
        addr8.address
      );

      const balanceaddr8After = await ovrToken.balanceOf(addr8.address);

      console.log(
        "\t\t\tStakingRewardsRewards User Balance After:",
        fromWei(addr8rewardsAfter.toString())
      );

      console.log(
        "\t\t\taddr8 Balance after",
        fromWei(balanceaddr8After.toString())
      );
      expect(
        fromWei(addr8rewardsAfter.toString()),
        "User Rewards balance should be sam of calculated reards"
      ).to.equal(fromWei(calculatedRewards.toString()));
    });

    it("It should be 12 months since the start", async () => {
      currentBlock = await time.latest();

      await time.increase(month * 12);

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
});
