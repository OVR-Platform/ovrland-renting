/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers");

const cyan = "\x1b[36m%s\x1b[0m";
const yellow = "\x1b[33m%s\x1b[0m";

const DAY = 86400;
const MONTH = DAY * 30; // Supposing every month 30 days
const HOUR = DAY / 24; // Supposing every month 30 days

// Get date from unix timestamp
const displayTime = (unixTime) => {
  const date = new Date(unixTime * 1000).toLocaleString("it-IT");
  return date;
};

const displayBalance = async (user, contract, logText) => {
  const balance = await contract.balanceOf(user.address);
  console.debug(`\t\t\t${logText} ${yellow}`, fromWei(balance.toString()));
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
};

const fromWei = (stringValue) => ethers.utils.formatUnits(stringValue, 18);
const toWei = (value) => ethers.utils.parseEther(value);

describe.only("OVRLand Renting - TEST", async () => {
  let Renting, renting;
  let ProxyRenting;
  let OVRLand, ovrLand;
  let OVRToken, ovrToken;
  let OVRLandExperience, ovrLandExperience;
  let Hosting, hosting;
  let OVRContainer, ovrContainer;

  beforeEach(async () => {
    Renting = await ethers.getContractFactory("OVRLandRenting");
    OVRLand = await ethers.getContractFactory("OVRLand");
    OVRToken = await ethers.getContractFactory("OVRToken");
    OVRLandExperience = await ethers.getContractFactory("OVRLandExperience");
    Hosting = await ethers.getContractFactory("OVRLandHosting");
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

  describe("Current Block", () => {
    it("Should exist", async () => {
      displayBlockTime();
    });
  });

  /* ****** OVRLAND DEPLOYMENT AND MINT ****** */
  describe("OVRLand Contract Deployment and mint", () => {
    it("Should deploy", async () => {
      ovrLand = await OVRLand.deploy();
      await ovrLand.deployed();
      landAddress = ovrLand.address;
      console.debug(`\t\t\tOVRLand: ${cyan}`, landAddress);
    });
    it("Owner should mint Lands (total supply)", async () => {
      await ovrLand.mint(owner.address, 1);

      const ownerOVRLandBalance = await ovrLand.balanceOf(owner.address);
      const TotalSupply = await ovrLand.totalSupply();
      expect(ownerOVRLandBalance.toString()).to.equal(TotalSupply);
    });
    it("Owner should own LandId 1", async () => {
      const addressLandOwner = await ovrLand.ownerOf(1);
      expect(addressLandOwner.toString()).to.equal(owner.address);
    });
    it("Addr2 should own LandId 2", async () => {
      await ovrLand.connect(owner).mint(addr2.address, 2);
      const addressLandOwner = await ovrLand.ownerOf(2);
      expect(addressLandOwner.toString()).to.equal(addr2.address);
    });
    it("Addr3 should own LandId 3", async () => {
      await ovrLand.connect(owner).mint(addr3.address, 3);
      const addressLandOwner = await ovrLand.ownerOf(3);
      expect(addressLandOwner.toString()).to.equal(addr3.address);
    });
    it("Addr4 should own LandId 4", async () => {
      await ovrLand.connect(owner).mint(addr4.address, 4);
      const addressLandOwner = await ovrLand.ownerOf(4);
      expect(addressLandOwner.toString()).to.equal(addr4.address);
    });
    it("Addr5 should own LandId 5", async () => {
      await ovrLand.connect(owner).mint(addr5.address, 5);
      const addressLandOwner = await ovrLand.ownerOf(5);
      expect(addressLandOwner.toString()).to.equal(addr5.address);
    });
    it("Addr6 should own LandId 11,12,13,14", async () => {
      await ovrLand.mint(addr6.address, 11);
      await ovrLand.mint(addr6.address, 12);
      await ovrLand.mint(addr6.address, 13);
      await ovrLand.mint(addr6.address, 14);
    });
  });

  /* ****** OVRLAND CONTAINER DEPLOYMENT ****** */
  describe("OVRLand Container Deployment", () => {
    it("Should deploy", async () => {
      ovrContainer = await OVRContainer.deploy();
      await ovrContainer.deployed();
      containerAddress = ovrContainer.address;
      console.debug(`\t\t\tOVRLandContainer: ${cyan}`, containerAddress);
    });
    it("should initialize container", () => {
      ovrContainer.connect(owner).initialize(landAddress, 50);
    });
  });

  /* ****** OVR TOKEN DEPLOYMENT AND MINT ****** */
  describe("Deploy OVR Token ERC20", async () => {
    it("Should deploy", async () => {
      ovrToken = await OVRToken.deploy();
      await ovrToken.deployed();
      console.debug(`\t\t\tOVRToken: ${cyan}`, ovrToken.address);
    });
    it("Trasfer 1000 OVR to addr1", async () => {
      await ovrToken.connect(owner).transfer(addr1.address, toWei("1000"));
      const bal = await ovrToken.connect(addr1).balanceOf(addr1.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
    it("Trasfer 1000 OVR to addr2", async () => {
      await ovrToken.connect(owner).transfer(addr2.address, toWei("1000"));
      const bal = await ovrToken.connect(addr2).balanceOf(addr2.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
    it("Trasfer 1000 OVR to addr3", async () => {
      await ovrToken.connect(owner).transfer(addr3.address, toWei("1000"));
      const bal = await ovrToken.connect(addr3).balanceOf(addr3.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
    it("Trasfer 1000 OVR to addr4", async () => {
      await ovrToken.connect(owner).transfer(addr4.address, toWei("1000"));
      const bal = await ovrToken.connect(addr4).balanceOf(addr4.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
    it("Trasfer 1000 OVR to addr5", async () => {
      await ovrToken.connect(owner).transfer(addr5.address, toWei("1000"));
      const bal = await ovrToken.connect(addr5).balanceOf(addr5.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
    it("Trasfer 1000 OVR to addr6", async () => {
      await ovrToken.connect(owner).transfer(addr6.address, toWei("1000"));
      const bal = await ovrToken.connect(addr6).balanceOf(addr6.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
    it("Trasfer 1000 OVR to addr7", async () => {
      await ovrToken.connect(owner).transfer(addr7.address, toWei("1000"));
      const bal = await ovrToken.connect(addr7).balanceOf(addr7.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
    it("Trasfer 1000 OVR to addr8", async () => {
      await ovrToken.connect(owner).transfer(addr8.address, toWei("1000"));
      const bal = await ovrToken.connect(addr8).balanceOf(addr8.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
    it("Trasfer 1000 OVR to addr9", async () => {
      await ovrToken.connect(owner).transfer(addr9.address, toWei("1000"));
      const bal = await ovrToken.connect(addr9).balanceOf(addr9.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
    it("Trasfer 1000 OVR to addr10", async () => {
      await ovrToken.connect(owner).transfer(addr10.address, toWei("1000"));
      const bal = await ovrToken.connect(addr10).balanceOf(addr10.address);
      expect(fromWei(bal.toString())).to.equal("1000.0");
    });
  });

  /* ****** OVRLAND RENTING AND MINT ****** */
  describe("Deploy OVRLandRenting", async () => {
    it("Should deploy OVRLand Renting", async () => {
      ProxyRenting = await upgrades.deployProxy(
        Renting,
        [
          ovrToken.address, // OVR ERC20
          ovrLand.address, // OVRLand ERC721
          "0x0000000000000000000000000000000000000000", // OVRLand Experience Contract
          "0x0000000000000000000000000000000000000000", // OVRLand Hosting Contract
          addr18.address, // feeReceiver
          "100000000000000000000", // NO_RENT price (100 OVR)
          "1000000000000000000000", // RENT price (100 OVR)
          ovrContainer.address,
          "30", // BASE PRICE LAND (3$)
          "4", // BASE PRICE CONTAINER (4$)
        ],
        {
          initializer: "initialize",
          kind: "uups",
        }
      );
      await ProxyRenting.deployed();
      console.debug(`\t\t\tProxyRenting: ${cyan}`, ProxyRenting.address);
    });
  });

  /* ****** OVRLAND EXPERIENCE AND MINT ****** */
  describe("Deploy OVRLandExperience", async () => {
    it("Should deploy OVRLandExperience", async () => {
      ovrLandExperience = await OVRLandExperience.deploy();
      await ovrLandExperience.deployed();
      await ovrLandExperience.initialize(
        ovrLand.address,
        ProxyRenting.address,
        ovrContainer.address
      );

      console.debug(
        `\t\t\tOVRLandExperience: ${cyan}`,
        ovrLandExperience.address
      );
    });
    it("Should set correct OVRLandExperience address on OVRLandRenting", async () => {
      await ProxyRenting.connect(owner).setOVRLandExperienceAddress(
        ovrLandExperience.address
      );
      const addr = await ProxyRenting.connect(owner).OVRLandExperience.call();
      expect(ovrLandExperience.address).to.equal(addr);
      await ovrContainer.setExperienceAddress(ovrLandExperience.address);
    });
  });

  describe("deploy OVRhosting", async () => {
    it("Should deploy OVRhosting", async () => {
      hosting = await Hosting.deploy();
      hosting.deployed();
      hosting.initialize(
        ProxyRenting.address,
        ovrLand.address,
        addr18.address,
        ovrToken.address
      );
      console.debug(`\t\t\tOVRhosting: ${cyan}`, hosting.address);
      await ProxyRenting.setHostingContract(hosting.address);
    });
  });

  describe("First Round", async () => {
    it("Addr5 places order of 25 OVR (2 months) for LandId 2", async () => {
      await ovrToken
        .connect(addr5)
        .approve(ProxyRenting.address, toWei("100000"));

      console.log("\t\tBefore placeOffer()");

      await displayBalance(addr5, ovrToken, "Addr5 Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");

      console.log("\t\tAfter print");
      await ProxyRenting.connect(addr5).placeOffer(
        ovrLand.address,
        2,
        toWei("25"),
        2,
        "https://www.google.com/"
      );

      console.log("\t\tAfter placeOffer()");

      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr5, ovrToken, "Addr5 Balance:");
    });

    it("SHOULD FAIL Addr6 places order of 20 OVR (2 months) for LandId 2", async () => {
      await ovrToken
        .connect(addr6)
        .approve(ProxyRenting.address, toWei("100000"));

      await expect(
        ProxyRenting.connect(addr6).placeOffer(
          ovrLand.address,
          2,
          toWei("20"),
          2,
          "https://www.google.com/"
        )
      ).to.be.revertedWith("Offer is too low");
    });

    it("Move time forward", async () => {
      await time.increase(DAY * 3.1);
      displayBlockTime();
    });

    it("Owner should accept offer", async () => {
      console.debug("\t\tBefore acceptOffer()");

      await displayBalance(addr5, ovrToken, "Renter Balance:");
      await displayBalance(addr2, ovrToken, "Owner Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");

      await ProxyRenting.connect(addr2).acceptOffer(ovrLand.address, 2);

      console.debug("\t\tAfter acceptOffer()");
      await displayBalance(addr5, ovrToken, "Renter Balance:");
      await displayBalance(addr2, ovrToken, "Owner Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
    });

    it("Owner should activate no rent", async () => {
      console.debug("\t\tBefore activateNoRent()");
      await displayBalance(owner, ovrToken, "Owner Balance:");
      await ovrToken.approve(ProxyRenting.address, toWei("10000000"));
      await ProxyRenting.activateNoRent(ovrLand.address, 1, {
        pricePerMonth: toWei("10"),
        minMonths: 1,
        maxMonths: 3,
      });
      console.debug("\t\tAfter activateNoRent()");
      await displayBalance(owner, ovrToken, "Owner Balance:");
    });

    it("Addr6 places order of 20 OVR (2 months) for LandId 1", async () => {
      await ProxyRenting.connect(addr6).placeOffer(
        ovrLand.address,
        1,
        toWei("20"),
        2,
        "https://www.google.com/"
      );
    });

    it("Addr6 places order of 25 OVR (1 month) for LandId 3", async () => {
      await ovrToken
        .connect(addr6)
        .approve(ProxyRenting.address, toWei("10000000000"));

      console.log("\t\tBefore placeOffer()");

      await displayBalance(addr6, ovrToken, "Addr6 Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");

      await ProxyRenting.connect(addr6).placeOffer(
        ovrLand.address,
        3,
        toWei("25"),
        1,
        "https://www.google.com/"
      );

      console.log("\t\tAfter placeOffer()");

      await displayBalance(addr6, ovrToken, "Addr6 Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
    });

    it("Move time forward", async () => {
      await time.increase(DAY * 3.1);
      displayBlockTime();
    });

    it("Should FAIL call startOVRLandRenting() DIRECLY from OVRLandExperience", async () => {
      await expect(
        ovrLandExperience
          .connect(addr18)
          .startTokenRenting(
            ovrLand.address,
            3,
            addr14.address,
            1648415031,
            3,
            "https://www.google.com/"
          )
      ).to.be.revertedWith("Non valid execution");
    });

    it("Renter should accept offer, and Lands should be rented", async () => {
      console.debug("\t\tBefore acceptOffer()");

      await displayBalance(addr6, ovrToken, "Renter Balance:");
      await displayBalance(addr3, ovrToken, "Owner Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");

      await ProxyRenting.connect(addr6).acceptOffer(ovrLand.address, 3);

      console.debug("\t\tAfter acceptOffer()");
      await displayBalance(addr6, ovrToken, "Renter Balance:");
      await displayBalance(addr3, ovrToken, "Owner Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");

      const rented = await ovrLandExperience.isTokenRented(ovrLand.address, 3);
      expect(rented).to.equal(true);
    });
  });

  it("Move time forward", async () => {
    await time.increase(DAY * 4);
    displayBlockTime();
  });

  describe("Second Round", async () => {
    it("Renter(Addr7) places offer (50 OVR, 1 month) to Owner(Addr4) for LandId 4", async () => {
      await ovrToken
        .connect(addr7)
        .approve(ProxyRenting.address, toWei("100000"));

      console.debug("\t\tBefore placeOffer()");
      await displayBalance(addr7, ovrToken, "Renter Balance:");
      await displayBalance(addr4, ovrToken, "Owner Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");

      await ProxyRenting.connect(addr7).placeOffer(
        ovrLand.address,
        4,
        toWei("50"),
        1,
        "https://www.google.com/"
      );

      console.debug("\t\tAfter placeOffer()");
      await displayBalance(addr7, ovrToken, "Renter Balance:");
      await displayBalance(addr4, ovrToken, "Owner Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
    });

    it("Should FAIL: Renter(Addr7) try to accept offer(50 OVR, 1 month) of LandId 4 owned by Addr4 before 24h wait", async () => {
      await time.increase(HOUR * 2);

      await expect(
        ProxyRenting.connect(addr7).acceptOffer(ovrLand.address, 4)
      ).to.be.revertedWith("Not authorized");
    });

    it("Should FAIL: Renter(Addr8) overbid (80 OVR, 2 month) of LandId 4 owned by Addr4, then previous offerer(Addr7) try to accept after 48h", async () => {
      await ovrToken
        .connect(addr8)
        .approve(ProxyRenting.address, toWei("100000"));

      await ProxyRenting.connect(addr8).placeOffer(
        ovrLand.address,
        4,
        toWei("80"),
        1,
        "https://www.google.com/"
      );

      console.debug("\t\tAfter placeOffer()");
      await displayBalance(addr7, ovrToken, "Renter Balance:");
      await displayBalance(addr8, ovrToken, "New Renter Balance:");
      await displayBalance(addr4, ovrToken, "Owner Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");

      await time.increase(HOUR * 48);

      await expect(
        ProxyRenting.connect(addr7).acceptOffer(ovrLand.address, 4)
      ).to.be.revertedWith("Not authorized");
    });
    it("Should FAIL: Real Offerer try to accept 9 days after after", async () => {
      await time.increase(DAY * 9);

      await expect(
        ProxyRenting.connect(addr8).acceptOffer(ovrLand.address, 4)
      ).to.be.revertedWith("Acceptance time window of 7 days expired");
    });

    it("add tier hosting fees", async () => {
      await hosting.addTier(0, toWei("1"), 1, 50, true);
    });
    it("pay hosting fees", async () => {
      await ovrToken.approve(hosting.address, toWei("187654567899876"));
      await hosting.payFees(1, 0, true);
    });
    it("noRent is active?", async () => {
      const active = await ProxyRenting.isNoRentActive(ovrLand.address, 1);
      expect(active).to.equal(true);
      console.debug("\t\tNoRent is active? ", active);
    });
    it("Move time forward", async () => {
      await time.increase(DAY * 35);
      displayBlockTime();
    });
    it("noRent is active after 35 days?", async () => {
      const active = await ProxyRenting.isNoRentActive(ovrLand.address, 1);
      expect(active).to.equal(false);
      console.debug("\t\tNoRent is active? ", active);
    });

    it("update hosting tier 0", async () => {
      await hosting.updateTier(2, 2, 0);
    });
    it("pay hosting fees", async () => {
      await hosting.payFees(1, 0, true);
    });
    it("noRent is active?", async () => {
      const active = await ProxyRenting.isNoRentActive(ovrLand.address, 1);
      expect(active).to.equal(true);
      console.debug("\t\tNoRent is active? ", active);
    });
    it("Move time forward", async () => {
      await time.increase(DAY * 35);
      displayBlockTime();
    });
    it("noRent is active after 35 days?", async () => {
      const active = await ProxyRenting.isNoRentActive(ovrLand.address, 1);
      expect(active).to.equal(true);
      console.debug("\t\tNoRent is active? ", active);
    });
    it("Move time forward", async () => {
      await time.increase(DAY * 35);
      displayBlockTime();
    });
    it("noRent is active after 70 days?", async () => {
      const active = await ProxyRenting.isNoRentActive(ovrLand.address, 1);
      expect(active).to.equal(false);
      console.debug("\t\tNoRent is active? ", active);
    });

    it("addr6 should make a container with land 11,12,13", async () => {
      await ovrLand
        .connect(addr6)
        .setApprovalForAll(ovrContainer.address, true);
      await ovrContainer.connect(addr6).createContainer([11, 12, 13], "test");
    });
    it("check container name", async () => {
      const name = await ovrContainer.connect(addr6).containerName(0);
      expect(name).to.equal("test");
      console.debug("\t\tContainer name: ", name);
    });
    it("addr5 make offer for 1 month to container 0", async () => {
      console.log("\t\tBefore placeOffer()");

      await displayBalance(addr5, ovrToken, "Addr5 Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await ProxyRenting.connect(addr5).placeOffer(
        ovrContainer.address,
        0,
        toWei("25"),
        1,
        "https://www.google.com/"
      );
      console.log("\t\tAfter placeOffer()");

      await displayBalance(addr5, ovrToken, "Addr5 Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
    });
    it("Move time forward", async () => {
      await time.increase(DAY * 3.1);
      displayBlockTime();
    });
    it("addr5 should accept offer", async () => {
      console.debug("\t\tBefore acceptOffer()");

      await displayBalance(addr5, ovrToken, "Renter Balance:");
      await displayBalance(addr6, ovrToken, "Owner Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
      await ProxyRenting.connect(addr5).acceptOffer(ovrContainer.address, 0);

      console.debug("\t\tAfter acceptOffer()");

      await displayBalance(addr5, ovrToken, "Renter Balance:");
      await displayBalance(addr6, ovrToken, "Owner Balance:");
      await displayBalance(ProxyRenting, ovrToken, "Contract Balance:");
      await displayBalance(addr18, ovrToken, "Fee Receiver Balance:");
    });
    it("SHOULD FAIL: addr6 should destroy container 0", async () => {
      await expect(
        ovrContainer.connect(addr6).deleteContainer(0)
      ).to.be.revertedWith("Container is rented");
    });
    it("Move time forward", async () => {
      await time.increase(MONTH * 1.1);
      displayBlockTime();
    });
    it("addr5 should try to place an offer for land 12 (it's inside the container)", async () => {
      await ProxyRenting.connect(addr5).placeOffer(
        ovrLand.address,
        12,
        toWei("25"),
        1,
        "https://www.google.com/"
      );
    });
    it("Move time forward", async () => {
      await time.increase(DAY * 3.1);
      displayBlockTime();
    });
    it("addr5 should accept offer", async () => {
      await expect(
        ProxyRenting.connect(addr5).acceptOffer(ovrLand.address, 12)
      ).to.be.revertedWith("Land is inside a container");
    });

    it(" addr6 should destroy container 0", async () => {
      await ovrContainer.connect(addr6).deleteContainer(0);
    });
    it("addr5 should accept offer", async () => {
      await ProxyRenting.connect(addr5).acceptOffer(ovrLand.address, 12);
    });
    it("Move time forward", async () => {
      await time.increase(MONTH * 13);
      displayBlockTime();
    });

    it("owner should activate no rent for land 1", async () => {
      console.debug("\t\tBefore activateNoRent()");
      await displayBalance(owner, ovrToken, "Owner Balance:");
      await ovrToken.approve(ProxyRenting.address, toWei("10000000"));
      await ProxyRenting.activateNoRent(ovrLand.address, 1, {
        pricePerMonth: toWei("10"),
        minMonths: 2,
        maxMonths: 3,
      });
      console.debug("\t\tAfter activateNoRent()");
      await displayBalance(owner, ovrToken, "Owner Balance:");
    });

    it("addr5 should try to place an offer for land 1", async () => {
      await ProxyRenting.connect(addr5).placeOffer(
        ovrLand.address,
        1,
        toWei("25"),
        2,
        "https://www.google.com/"
      );
    });

    it("Move time forward", async () => {
      await time.increase(DAY * 3.1);
      displayBlockTime();
    });

    it("addr5 should accept offer", async () => {
      await ProxyRenting.connect(addr5).acceptOffer(ovrLand.address, 1);
    });
    it("Move time forward", async () => {
      await time.increase(MONTH * 2.1);
      displayBlockTime();
    });
    it("addr5 should try to place an offer for land 1", async () => {
      await ProxyRenting.connect(addr5).placeOffer(
        ovrLand.address,
        1,
        toWei("25"),
        1,
        "https://www.google.com/"
      );
    });
    it("Move time forward", async () => {
      await time.increase(DAY * 3.1);
      displayBlockTime();
    });
    it("addr5 should accept offer", async () => {
      await expect(
        ProxyRenting.connect(addr5).acceptOffer(ovrLand.address, 1)
      ).to.be.revertedWith("Invalid months number");
    });
    it("owner of land 1 should accept offer", async () => {
      await ProxyRenting.connect(owner).acceptOffer(ovrLand.address, 1);
    });
  });
});
