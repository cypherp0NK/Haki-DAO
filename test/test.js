const { expect } = require("chai");

describe("Unit Tests", function () {
  before(async function () {
    const ContractFactory = await ethers.getContractFactory("HakiDAO");
    HakiDAO = await ContractFactory.deploy();
    await HakiDAO.deployed("", "", "", "");
  });

  it("Submit Proposal", async function () {
    await expect(
      HakiDAO.submitProposal()
    ).not.to.be.reverted;
  });
  it("Vote", async function () {
    await expect(HakiDAO.vote(1)).to.be.reverted;
  });
  it("Claim Rewards", async function () {
    await expect(HakiDAO.claimRewards(1, 0)).to.be.reverted;
  });
  it("Adjust Rewards", async function () {
    await expect(HakiDAO.submitProposal()).not.to.be.reverted;
  });




});
