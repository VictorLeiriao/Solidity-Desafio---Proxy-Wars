import { ethers } from "hardhat";

async function main() {
  // O endereço do teu Proxy na rede Amoy
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";
  
  // As tuas configurações da DEX
  const TOKEN_ADDRESS = "0x6a9736e95fDff0010E679A1120C053179a10c0a4";
  const TAXA_CAMBIO = 100; // 1 POL compra 100 Tokens

  const [dono] = await ethers.getSigners();
  console.log("A iniciar a configuração da DEX com a conta:", dono.address);

  // Conectamos ao contrato usando a 'cara' da V6
  const bank = await ethers.getContractAt("BankV6", PROXY_ADDRESS);

  console.log(`\n1. A configurar o endereço do Token de Câmbio para: ${TOKEN_ADDRESS}...`);
  const txToken = await bank.updateTokenExchange(TOKEN_ADDRESS);
  await txToken.wait(); // Esperamos que a rede Polygon confirme a transação
  console.log("✅ Token atualizado com sucesso!");

  console.log(`\n2. A configurar a Taxa de Câmbio para: 1 POL = ${TAXA_CAMBIO} Tokens...`);
  const txFee = await bank.updateFeeExchange(TAXA_CAMBIO);
  await txFee.wait();
  console.log("✅ Taxa de câmbio atualizada com sucesso!");

  console.log("\n🎉 A TUA CORRETORA ESTÁ OFICIALMENTE CONFIGURADA E ABERTA PARA NEGÓCIO!");
  console.log("Próximo passo: Usa o painel de Admin para adicionar a liquidez inicial.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});