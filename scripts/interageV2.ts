import { ethers } from "hardhat";

async function main() {
  // O seu endereço fixo e blindado do Proxy!
  const PROXY_ADDRESS = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";

  // Pegamos a Conta 2 que você já configurou no hardhat.config.ts
  const [dono, usuario2] = await ethers.getSigners();
  console.log("Conectado como Usuário 2:", usuario2.address);

  // Agora conectamos avisando o Hardhat que as regras mudaram para a BankV2
  const bank = await ethers.getContractAt("BankV2", PROXY_ADDRESS);

  // =========================================================
  // 1. O DEPÓSITO
  // =========================================================
  const valorDeposito = ethers.parseEther("0.05"); // 0.05 POL
  console.log(`\n💸 1. Depositando 0.05 POL no banco...`);
  
  let tx = await bank.connect(usuario2).deposit({ value: valorDeposito });
  await tx.wait();
  console.log("✅ Depósito confirmado na blockchain!");

  // =========================================================
  // 2. VER SALDO (Usando a sua função nova!)
  // =========================================================
  let saldo = await bank.getAccountBalance(usuario2.address);
  console.log(`\n🏦 2. Consultando saldo via getAccountBalance...`);
  console.log(`Saldo atual: ${ethers.formatEther(saldo)} POL`);

  // =========================================================
  // 3. O SAQUE (Testando a taxa e a trava padrão)
  // =========================================================
  const valorSaque = ethers.parseEther("0.02"); // 0.02 POL
  console.log(`\n🏧 3. Solicitando saque de 0.02 POL...`);
  
  tx = await bank.connect(usuario2).withdraw(valorSaque);
  await tx.wait();
  console.log("✅ Saque confirmado!");

  // =========================================================
  // 4. CONFERÊNCIA FINAL
  // =========================================================
  saldo = await bank.getAccountBalance(usuario2.address);
  console.log(`\n📉 Saldo final após o desconto da taxa: ${ethers.formatEther(saldo)} POL`);
  
  // Vamos dar uma espiada no cofre do dono para ver se a taxa foi arrecadada?
  // Qualquer um pode ler uma variável pública!
  const lucroDoBanco = await bank.totalWithdrawFeeCollected();
  console.log(`💰 Lucro total acumulado para o Dono do banco: ${ethers.formatEther(lucroDoBanco)} POL`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});