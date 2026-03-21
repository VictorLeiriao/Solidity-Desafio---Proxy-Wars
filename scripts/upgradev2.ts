import { ethers, upgrades } from "hardhat";

async function main() {
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";

  const [dono] = await ethers.getSigners();
  console.log("Iniciando o Upgrade usando a conta do Dono (Admin):", dono.address);

  const BankV2 = await ethers.getContractFactory("BankV2");

  const feeInitial = ethers.parseEther("0.001");

  console.log("Fazendo o deploy da Implementação V2");

  const upgradedBank = await upgrades.upgradeProxy(PROXY_ADDRESS, BankV2, {
    kind: "uups",
    call: { fn: "initializeV2", args: [feeInitial] } 
  });

  await upgradedBank.waitForDeployment();

  console.log("✅ UPGRADE REALIZADO COM SUCESSO!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});