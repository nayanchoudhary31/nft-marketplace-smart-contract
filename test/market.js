const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");

describe("Market TestCases", () => {
  let account1;
  let account2;
  let account3;
  let Market;
  let market;
  let NFT;
  let nft;
  const tokenId = 0;
  const listingID = 1;
  const price = 1000;
  beforeEach(async () => {
    [account1, account2, account3] = await ethers.getSigners();
    Market = await ethers.getContractFactory("Market");
    market = await Market.deploy();
    await market.deployed();

    NFT = await ethers.getContractFactory("NFT");
    nft = await NFT.deploy();

    await nft.safeMint();
  });

  describe("List Token Function", async () => {
    it("should list token if approved", async () => {
      await nft.approve(market.address, tokenId);

      await expect(
        market.connect(account1).listToken(nft.address, tokenId, price)
      )
        .to.emit(market, "ListingToken")
        .withArgs(1, account1.address, nft.address, tokenId, price);
    });
    it("should revert if market is not approved", async () => {
      return expectRevert(
        market.listToken(nft.address, tokenId, price),
        "ERC721: transfer caller is not owner nor approved"
      );
    });
  });

  describe("Buyer Tokens", () => {
    it("Seller can not buy Token", async () => {
      await nft.connect(account1).approve(market.address, tokenId);
      await market.connect(account1).listToken(nft.address, tokenId, price);

      await expect(
        market.connect(account1).buyToken(listingID)
      ).to.be.revertedWith("Seller can't be Buyer");
    });

    it("Can not Buy Not Acitve Token", async () => {
      await nft.connect(account1).approve(market.address, tokenId);

      await market.connect(account1).listToken(nft.address, tokenId, price);

      await expect(
        market.connect(account2).buyToken(listingID)
      ).to.be.revertedWith("Insufficient amount");
    });
  });
});
