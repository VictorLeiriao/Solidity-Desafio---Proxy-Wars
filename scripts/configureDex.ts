import { ethers } from "hardhat";

async function main() {
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";
  const TOKEN_ADDRESS = "0x6a9736e95fDff0010E679A1120C053179a10c0a4";
  const TAXA_CAMBIO = 100; // 1 POL compra 100 Tokens

  const [dono] = await ethers.getSigners();
  console.log("A iniciar a configuração da DEX com a conta:", dono.address);

  // Conectamos no Proxy assumindo que ele JÁ É a V6
  const bank = await ethers.getContractAt("BankV6", PROXY_ADDRESS);

  console.log(`\n1. A configurar o endereço do Token de Câmbio para: ${TOKEN_ADDRESS}...`);
  const txToken = await bank.updateTokenExchange(TOKEN_ADDRESS);
  await txToken.wait();
  console.log("✅ Token atualizado com sucesso!");

  console.log(`\n2. A configurar a Taxa de Câmbio para: 1 POL = ${TAXA_CAMBIO} Tokens...`);
  const txFee = await bank.updateFeeExchange(TAXA_CAMBIO);
  await txFee.wait();
  console.log("✅ Taxa de câmbio atualizada com sucesso!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});