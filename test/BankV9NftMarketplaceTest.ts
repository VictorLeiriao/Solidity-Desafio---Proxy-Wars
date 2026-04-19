import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("Bank Proxy Wars - Testes V9 (NFT Marketplace + onlyRegistered buy)", function () {
  it("deve listar, comprar (somente cadastrado) e cancelar", async function () {
    const [owner, buyer, outsider] = await ethers.getSigners();

    const BankV9 = await ethers.getContractFactory("BankV9");
    const bank = await upgrades.deployProxy(BankV9, [owner.address], { kind: "uups" });
    await bank.waitForDeployment();

    await bank.initializeV2(100); // 1% em BPS? (não importa para esse teste)
    await bank.initializeV3();
    await bank.initializeV9();

    const MockERC721 = await ethers.getContractFactory("MockERC721");
    const nft = await MockERC721.deploy("MockNFT", "MNFT");
    await nft.waitForDeployment();

    const tokenId = await nft.mint.staticCall(owner.address);
    await nft.mint(owner.address);
    await nft.connect(owner).setApprovalForAll(await bank.getAddress(), true);

    await expect(bank.connect(owner).listNft(await nft.getAddress(), tokenId, 0)).to.be.revertedWithCustomError(
      bank,
      "InvalidPrice"
    );

    await bank.connect(owner).listNft(await nft.getAddress(), tokenId, ethers.parseEther("1"));

    const listing0 = await bank.listings(0);
    expect(listing0.active).to.equal(true);

    // outsider não cadastrado: bloqueado
    await expect(bank.connect(outsider).buy(0, { value: ethers.parseEther("1") })).to.be.revertedWithCustomError(
      bank,
      "AccountNotRegistered"
    );

    // buyer cadastra e compra
    await bank.connect(buyer).registerRequest("Buyer", 30, "BR");
    await expect(bank.connect(buyer).buy(0, { value: ethers.parseEther("0.5") })).to.be.revertedWithCustomError(
      bank,
      "WrongPayment"
    );

    await bank.connect(buyer).buy(0, { value: ethers.parseEther("1") });
    expect(await nft.ownerOf(tokenId)).to.equal(buyer.address);

    const listingAfter = await bank.listings(0);
    expect(listingAfter.active).to.equal(false);

    // cancel em listing inativo deve falhar
    await expect(bank.connect(owner).cancelListing(0)).to.be.revertedWithCustomError(bank, "ListingNotActive");
  });
});

