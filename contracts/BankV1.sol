// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BankV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
   
    // Guarda o saldo GRAFICO de cada usuário 
    mapping(address => uint256) public balance;

    // Gero evento na rede para conseguir rastrear as movimentacoes
    event DepositMade(address indexed user, uint256 cashValue);
    event WithdrawMade(address indexed user, uint256 cashValue);

    // Segurança?
    constructor() {
        // Trava o contrato de implementação para que ninguém possa inicializá-lo diretamente
        _disableInitializers();
    }

    
    function initialize(address _owner) public initializer {
        // Inicializa o controle de acesso (Ownable) definindo quem é o dono
        __Ownable_init(_owner);
    }

    function deposit() public payable {
        require(msg.value > 0, "O valor do deposito deve ser maior que zero");
        
        balance[msg.sender] += msg.value;
        
        emit DepositMade(msg.sender, msg.value);
    }

    function withdraw(uint256 _cashValue) public {
        require(_cashValue > 0, "Hm... ta brincando comigo ne?... saldo tem que ser maior que ZERO rapaz!!!");
        require(balance[msg.sender] >= _cashValue, "Ta... boa tentativa kkkk, voce nao tem saldo para isso amigao!");

        balance[msg.sender] -= _cashValue;

        (bool sucess, ) = payable(msg.sender).call{value: _cashValue}("");
        require(sucess, "Falha ao enviar ether");

        emit WithdrawMade(msg.sender, _cashValue);
    }

    /**
     * @dev Função exigida pelo padrão UUPS para autorizar um upgrade.
     * O modificador `onlyOwner` garante que apenas o dono do banco possa atualizar a lógica.
     * Se você esquecer o onlyOwner aqui, qualquer um pode hackear o contrato inserindo uma V2 maliciosa!
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}