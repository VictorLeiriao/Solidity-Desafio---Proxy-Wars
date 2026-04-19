import { ethers, upgrades } from "hardhat";

async function main() {
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";

  const [dono] = await ethers.getSigners();
  console.log("Iniciando o Upgrade para V9 (NFT Marketplace) com a conta:", dono.address);

  const BankV9 = await ethers.getContractFactory("BankV9");

  const upgradedBank = await upgrades.upgradeProxy(PROXY_ADDRESS, BankV9, {
    call: { fn: "initializeV9", args: [] },
  });
  await upgradedBank.waitForDeployment();

  console.log("✅ UPGRADE PARA V9 REALIZADO COM SUCESSO!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

