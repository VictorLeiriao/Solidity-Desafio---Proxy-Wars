import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("Bank Proxy Wars - Testes V4 (KYC e Whitelist)", function () {
  let bankProxy: any;
  let owner: any;
  let user1: any;
  let hacker: any;

  beforeEach(async function () {
    [owner, user1, hacker] = await ethers.getSigners();

    // O Hardhat permite simular o Proxy direto na versão mais recente para pouparmos código
    const BankV4 = await ethers.getContractFactory("BankV4");
    bankProxy = await upgrades.deployProxy(BankV4, [owner.address], { kind: "uups" });
    await bankProxy.waitForDeployment();

    // Ligamos as configurações das versões antigas
    await bankProxy.initializeV2(ethers.parseEther("1")); // Taxa de 1 POL
    await bankProxy.initializeV3(); // isPaused = false

    // Como o dono é dono, ele se auto-aprova para facilitar a vida
    await bankProxy.approveAccount(owner.address);
  });

  it("1. Deve bloquear deposito de usuario que nao fez o cadastro", async function () {
    // Usuário 1 tenta depositar sem se cadastrar e dá de cara com o Guarda de Trânsito
    await expect(
      bankProxy.connect(user1).deposit({ value: ethers.parseEther("10") })
    ).to.be.revertedWith("Acesso negado: Faca seu cadastro primeiro!");
  });

  it("2. Deve barrar menores de idade no momento do cadastro", async function () {
    // Pedrinho tenta se cadastrar e a ficha na memória rejeita ele
    await expect(
      bankProxy.connect(user1).registerRequest("Pedrinho", 17, "Brasil")
    ).to.be.revertedWith("Voce deve ter mais de 18 anos para se registrar");
  });

  it("3. Deve validar a memoria temporaria, salvar na Whitelist e liberar acesso", async function () {
    // João (25) faz o cadastro e gasta Gás apenas para a transação
    await bankProxy.connect(user1).registerRequest("Joao", 25, "Brasil");

    // Lemos a blockchain para ver se o nome dele ficou salvo? NÃO! Apenas um booleano:
    const estaAprovado = await bankProxy.isWhitelisted(user1.address);
    expect(estaAprovado).to.be.true;

    // Agora o depósito deve passar livremente
    await bankProxy.connect(user1).deposit({ value: ethers.parseEther("10") });
    
    const saldo = await bankProxy.getAccountBalance(user1.address);
    expect(saldo).to.equal(ethers.parseEther("10"));
  });

  it("4. O Admin deve conseguir congelar a conta de um mau ator", async function () {
    // O Hacker engana o cadastro dizendo que tem 30 anos
    await bankProxy.connect(hacker).registerRequest("Sr. Hacker", 30, "Russia");
    
    // Ele faz um depósito
    await bankProxy.connect(hacker).deposit({ value: ethers.parseEther("5") });

    // O Admin descobre que ele é um hacker e puxa o botão de bloqueio
    await bankProxy.connect(owner).blockAccount(hacker.address);

    // O Hacker tenta fugir e sacar o dinheiro dele, mas a conta está congelada!
    await expect(
      bankProxy.connect(hacker).withdraw(ethers.parseEther("1"))
    ).to.be.revertedWith("Acesso negado: Faca seu cadastro primeiro!");
  });
});