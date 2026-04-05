import { ethers, upgrades } from "hardhat";

async function main() {
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";

  const [dono] = await ethers.getSigners();
  console.log("Iniciando o Upgrade para V7 (DEX) com a conta:", dono.address);

  // Puxa o contrato novo
  const BankV7 = await ethers.getContractFactory("BankV7");

  console.log("A instalar as prateleiras da Casa de Câmbio no Banco...");

  // O comando mágico que faltou para o Proxy enxergar as novas funções!
  const upgradedBank = await upgrades.upgradeProxy(PROXY_ADDRESS, BankV7);
  await upgradedBank.waitForDeployment();

  console.log("✅ UPGRADE PARA V7 REALIZADO COM SUCESSO!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});