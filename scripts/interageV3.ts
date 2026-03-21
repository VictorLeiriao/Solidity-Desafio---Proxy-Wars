import { ethers } from "hardhat";

async function main() {
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";

  // Conecta ao Proxy avisando que ele agora é V3
  const bank = await ethers.getContractAt("BankV3", PROXY_ADDRESS);

  console.log("A consultar o banco blindado na rede Polygon Amoy...");

  // Como já se passaram alguns minutos, todos os servidores já sincronizaram a V3
  const estadoPausa = await bank.isPaused();
  
  console.log(`\nEstado atual do Banco: ${estadoPausa ? "🔴 PAUSADO (Ninguém mexe no cofre!)" : "🟢 ATIVO (Movimentações liberadas)"}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});