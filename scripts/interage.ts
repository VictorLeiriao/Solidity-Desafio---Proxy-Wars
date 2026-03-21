import { ethers } from "hardhat";

async function main() {
  // O endereço fixo do seu Proxy que acabou de nascer!
  const ENDERECO_PROXY = "0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7";

  // Como colocamos duas chaves no hardhat.config.ts, o Hardhat nos dá as duas contas!
  const [dono, usuario2] = await ethers.getSigners();
  console.log("Conectado como Usuário 2:", usuario2.address);

  // Conecta ao contrato existente dizendo "Ei, leia o BankV1 que está neste endereço"
  const bank = await ethers.getContractAt("BankV1", ENDERECO_PROXY);

  // Vamos depositar 0.01 POL (Moeda Nativa da Amoy)
  const valorDeposito = ethers.parseEther("0.01");
  console.log(`Depositando 0.01 POL no banco...`);

  // A mágica acontece aqui: usamos o .connect(usuario2) para mudar quem está chamando a função!
  const tx = await bank.connect(usuario2).deposit({ value: valorDeposito });

  console.log("Transação enviada para a blockchain! Aguardando os mineradores...");
  
  // Espera a transação ser confirmada na rede
  await tx.wait(); 

  console.log("✅ Depósito confirmado! Hash da transação:", tx.hash);

  // Vamos conferir no storage do contrato se o saldo realmente atualizou?
  const saldoNoStorage = await bank.balance(usuario2.address);
  console.log("Novo saldo do Usuário 2 no storage do Banco:", ethers.formatEther(saldoNoStorage), "POL");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});