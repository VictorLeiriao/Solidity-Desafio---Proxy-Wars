import { ethers, upgrades } from "hardhat";

async function main() {
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";

  const [dono] = await ethers.getSigners();
  console.log("A iniciar o Upgrade para V4 com a conta:", dono.address);

  const BankV4 = await ethers.getContractFactory("BankV4");

  console.log("A instalar o sistema de KYC (Whitelist) na porta do banco...");

  const upgradedBank = await upgrades.upgradeProxy(PROXY_ADDRESS, BankV4);
  await upgradedBank.waitForDeployment();

  console.log("✅ UPGRADE PARA V4 REALIZADO COM SUCESSO! A catraca está trancada.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});