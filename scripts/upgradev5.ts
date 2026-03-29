import { ethers, upgrades } from "hardhat";

async function main() {
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";

  const [dono] = await ethers.getSigners();
  console.log("Iniciando o Upgrade para V5 com a conta:", dono.address);

  const BankV5 = await ethers.getContractFactory("BankV5");

  const upgradedBank = await upgrades.upgradeProxy(PROXY_ADDRESS, BankV5);
  await upgradedBank.waitForDeployment();

  console.log("✅ UPGRADE PARA V5 REALIZADO COM SUCESSO!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});