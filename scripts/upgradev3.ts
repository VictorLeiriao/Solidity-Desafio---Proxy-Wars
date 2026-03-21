import { ethers, upgrades } from "hardhat";

async function main() {
  // O teu Proxy de sempre!
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";

  const [dono] = await ethers.getSigners();
  console.log("A iniciar o Upgrade para V3 com a conta:", dono.address);

  const BankV3 = await ethers.getContractFactory("BankV3");

  console.log("A preparar a Implementação V3 e a ligar os Disjuntores...");

  // Fazemos o upgrade e chamamos o initializeV3 para garantir que não nasce já pausado
  const upgradedBank = await upgrades.upgradeProxy(PROXY_ADDRESS, BankV3, {
    kind: "uups",
    call: { fn: "initializeV3", args: [] } 
  });

  await upgradedBank.waitForDeployment();

  console.log("✅ UPGRADE PARA V3 REALIZADO COM SUCESSO!");
  
  const estadoPausa = await upgradedBank.isPaused();
  console.log(`Estado atual do Banco: ${estadoPausa ? "🔴 PAUSADO" : "🟢 ATIVO (A rodar perfeitamente)"}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});