import { expect } from "chai";
import hre, { network } from "hardhat";

// MÁGICA DO HARDHAT 3: O ethers agora vem da rede conectada!
const { ethers } = await network.connect();

describe("Proxy Wars - Fase de Testes V1", function () {
  
  let banco: any;
  let dono: any;
  let usuario1: any;

  beforeEach(async function () {
    [dono, usuario1] = await ethers.getSigners();

    const BankV1 = await ethers.getContractFactory("BankV1");

    // Usamos o (hre as any) para o TypeScript aceitar o plugin sem chiar
    banco = await (hre as any).upgrades.deployProxy(BankV1, [dono.address], {
      kind: "uups", 
    });

    await banco.waitForDeployment();
  });

  it("Deve definir o dono corretamente na inicializacao", async function () {
    expect(await banco.owner()).to.equal(dono.address);
  });

  it("Deve permitir que um usuario faça um deposito", async function () {
    const valorDeposito = ethers.parseEther("1.0"); 
    await banco.connect(usuario1).depositar({ value: valorDeposito });

    const saldoUsuario = await banco.saldos(usuario1.address);
    expect(saldoUsuario).to.equal(valorDeposito);
  });

  it("Deve permitir o saque do saldo e descontar corretamente", async function () {
    const valorDeposito = ethers.parseEther("2.0");
    const valorSaque = ethers.parseEther("0.5");

    await banco.connect(usuario1).depositar({ value: valorDeposito });
    await banco.connect(usuario1).sacar(valorSaque);

    const saldoRestante = await banco.saldos(usuario1.address);
    expect(saldoRestante).to.equal(ethers.parseEther("1.5"));
  });

  it("Nao deve permitir saque maior que o saldo", async function () {
    const valorDeposito = ethers.parseEther("1.0");
    await banco.connect(usuario1).depositar({ value: valorDeposito });

    await expect(
      banco.connect(usuario1).sacar(ethers.parseEther("2.0"))
    ).to.be.revertedWith("Saldo insuficiente");
  });
});