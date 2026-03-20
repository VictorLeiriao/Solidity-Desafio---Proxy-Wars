import { ethers, upgrades } from "hardhat";

async function main() {
  // Pega a primeira conta configurada no seu hardhat.config.ts
  const [deployer] = await ethers.getSigners();
  console.log("Iniciando o deploy com a conta:", deployer.address);

  // Carrega o contrato (Lembre-se de colocar o nome exato do seu contrato atualizado)
  const BankV1 = await ethers.getContractFactory("BankV1");

  console.log("Fazendo o deploy do Proxy, da Implementação V1 e inicializando...");
  
  // A mágica acontece aqui. O deployProxy cuida de tudo!
  const bank = await upgrades.deployProxy(BankV1, [deployer.address], {
    kind: "uups",
  });

  await bank.waitForDeployment();

  //✅ Banco Proxy (Endereço Fixo) deployado com sucesso em: 0x5f01cCFECe767EF5F72882F3D9F67274190eE2C7
  const proxyAddress = await bank.getAddress();
  console.log("✅ Banco Proxy (Endereço Fixo) deployado com sucesso em:", proxyAddress);
  console.log("Guarde esse endereço! É com ele que vamos interagir e fazer o upgrade depois.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});