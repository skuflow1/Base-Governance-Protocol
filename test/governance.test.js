// base-governance/test/governance.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Base Governance Protocol", function () {
  let governance;
  let governanceToken;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    
    // Деплой токена
    const GovernanceToken = await ethers.getContractFactory("ERC20Token");
    governanceToken = await GovernanceToken.deploy("Governance Token", "GOV");
    await governanceToken.deployed();
    
    // Деплой Governance Protocol
    const GovernanceProtocol = await ethers.getContractFactory("GovernanceProtocolV2");
    governance = await GovernanceProtocol.deploy(
      governanceToken.address,
      1000, // 10% quorum threshold
      86400, // 1 day voting delay
      604800, // 7 days voting period
      ethers.utils.parseEther("1000") // 1000 tokens minimum proposal threshold
    );
    await governance.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await governance.owner()).to.equal(owner.address);
    });

    it("Should initialize with correct parameters", async function () {
      expect(await governance.token()).to.equal(governanceToken.address);
      expect(await governance.quorumThreshold()).to.equal(1000);
      expect(await governance.votingDelay()).to.equal(86400);
      expect(await governance.votingPeriod()).to.equal(604800);
    });
  });

  describe("Proposal Creation", function () {
    it("Should create a proposal", async function () {
      await expect(governance.propose(
        [], // Empty proposal details
        "Test proposal",
        0, // Normal proposal type
        "" // Empty metadata
      )).to.emit(governance, "ProposalCreated");
    });
  });

  describe("Voting", function () {
    beforeEach(async function () {
      await governance.propose(
        [], // Empty proposal details
        "Test proposal",
        0, // Normal proposal type
        "" // Empty metadata
      );
    });

    it("Should cast a vote", async function () {
      await governanceToken.mint(addr1.address, ethers.utils.parseEther("1000"));
      await governanceToken.connect(addr1).approve(governance.address, ethers.utils.parseEther("1000"));
      
      await expect(governance.connect(addr1).vote(0, true))
        .to.emit(governance, "VoteCast");
    });
  });
});
