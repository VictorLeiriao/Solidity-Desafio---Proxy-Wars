import { expect } from "chai";
import { ethers, upgrades } from "hardhat"; // <-- Importação limpa e direta!

describe("Bank Proxy Wars - Fase de Testes V1", function () {
  
  let Bank: any;
  let owner: any;
  let user1: any;

  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();

    const BankV1 = await ethers.getContractFactory("BankV1");

    Bank = await upgrades.deployProxy(BankV1, [owner.address], {
      kind: "uups", 
    });

    await Bank.waitForDeployment();
  });

  it("Deve definir o owner corretamente na inicializacao", async function () {
    expect(await Bank.owner()).to.equal(owner.address);
  });

  it("Deve permitir que um usuario faça um deposito", async function () {
    const valorDeposito = ethers.parseEther("1.0"); 
    await Bank.connect(user1).depositar({ value: valorDeposito });

    const saldoUsuario = await Bank.saldos(user1.address);
    expect(saldoUsuario).to.equal(valorDeposito);
  });

  it("Deve permitir o saque do saldo e descontar corretamente", async function () {
    const valorDeposito = ethers.parseEther("2.0");
    const valorSaque = ethers.parseEther("0.5");

    await Bank.connect(user1).depositar({ value: valorDeposito });
    await Bank.connect(user1).sacar(valorSaque);

    const saldoRestante = await Bank.saldos(user1.address);
    expect(saldoRestante).to.equal(ethers.parseEther("1.5"));
  });

  it("Nao deve permitir saque maior que o saldo", async function () {
    const valorDeposito = ethers.parseEther("1.0");
    await Bank.connect(user1).depositar({ value: valorDeposito });

    await expect(
      Bank.connect(user1).sacar(ethers.parseEther("2.0"))
    ).to.be.revertedWith("Saldo insuficiente");
  });
});