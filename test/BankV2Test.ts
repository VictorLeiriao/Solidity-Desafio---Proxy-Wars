import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("Bank Proxy Wars - Fase de Testes V2", function () {
  let bankProxy: any; // O nosso banco que vai sofrer a mutação
  let owner: any;
  let user1: any;
  let hacker: any;

  // O beforeEach roda ANTES de cada teste abaixo. 
  // Ele vai simular exatamente o que fizemos na vida real!
  beforeEach(async function () {
    [owner, user1, hacker] = await ethers.getSigners();

    // 1. NASCE A V1
    const BankV1 = await ethers.getContractFactory("BankV1");
    bankProxy = await upgrades.deployProxy(BankV1, [owner.address], { kind: "uups" });
    await bankProxy.waitForDeployment();

    // 2. O USUÁRIO DEPOSITA DINHEIRO NA V1 (Para testarmos a memória)
    const depositoInicial = ethers.parseEther("100"); // 100 POL
    await bankProxy.connect(user1).deposit({ value: depositoInicial });

    // 3. FAZEMOS O UPGRADE PARA V2 NO MEIO DO CAMINHO!
    const BankV2 = await ethers.getContractFactory("BankV2");
    const taxaInicial = ethers.parseEther("1"); // A taxa será de 1 POL por saque
    const proxyAddress = await bankProxy.getAddress();

    // Atualiza o proxy e já chama a inicialização da V2
    bankProxy = await upgrades.upgradeProxy(proxyAddress, BankV2, {
      kind: "uups",
      call: { fn: "initializeV2", args: [taxaInicial] }
    });
    await bankProxy.waitForDeployment();
  });

  // =========================================================
  // BATERIA DE TESTES
  // =========================================================

  it("1. O Upgrade NAO pode apagar o saldo que o usuario tinha na V1", async function () {
    // O usuário 1 depositou 100 POL lá na V1. O saldo dele tem que continuar 100 aqui na V2!
    const saldoSalvo = await bankProxy.balance(user1.address);
    expect(saldoSalvo).to.equal(ethers.parseEther("100"));
  });

  it("2. Deve inicializar a V2 com a taxa de 1 POL definida no upgrade", async function () {
    const taxa = await bankProxy.getWithdrawFee();
    expect(taxa).to.equal(ethers.parseEther("1"));
  });

  it("3. Deve descontar a taxa de saque e guardar para o banco", async function () {
    // O usuário pede para sacar 10 POL
    const valorSaque = ethers.parseEther("10");
    await bankProxy.connect(user1).withdraw(valorSaque);

    // Como ele sacou 10, o saldo dele no mapping tem que cair de 100 para 90
    const saldoRestante = await bankProxy.balance(user1.address);
    expect(saldoRestante).to.equal(ethers.parseEther("90"));

    // Mas e a taxa? O contrato tem que ter guardado 1 POL (a taxa inicial) no cofre de lucros!
    const lucros = await bankProxy.totalWithdrawFeeCollected();
    expect(lucros).to.equal(ethers.parseEther("1"));
  });

  it("4. Apenas o Dono pode sacar os lucros (Hacker deve ser bloqueado)", async function () {
    // Gera lucro pro banco
    await bankProxy.connect(user1).withdraw(ethers.parseEther("10"));

    // O hacker tenta roubar as taxas usando a função do Admin
    await expect(
      bankProxy.connect(hacker).withdrawFeeAdmin()
    ).to.be.reverted; // O modificador onlyOwner bloqueia e reverte a transação!

    // Agora o dono verdadeiro saca as taxas com sucesso
    await bankProxy.connect(owner).withdrawFeeAdmin();

    // O cofre de lucros deve zerar após o saque
    const lucrosPosSaque = await bankProxy.totalWithdrawFeeCollected();
    expect(lucrosPosSaque).to.equal(0);
  });

  it("5. Deve impedir saques menores que o valor da taxa", async function () {
    // A taxa é 1 POL. Se o usuário tentar sacar 0.5 POL, tem que dar erro.
    const saquePequeno = ethers.parseEther("0.5");
    
    await expect(
      bankProxy.connect(user1).withdraw(saquePequeno)
    ).to.be.revertedWith("O saque nao cobre a taxa do banco");
  });
});