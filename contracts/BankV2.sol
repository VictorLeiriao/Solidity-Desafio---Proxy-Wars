// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

// 2. Voltamos a usar a versão Upgradeable na herança
contract BankV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    
    // NUNCA PODEMOS ALTERAR ORDEM DO QUE JÁ EXISTE == COLLISION :(
    mapping(address => uint256) public balance;

    // V2
    uint256 public withdrawFee;
    uint256 public totalWithdrawFeeCollected;

    event DepositMade(address indexed user, uint256 cashValue);
    event WithdrawMade(address indexed user, uint256 cashValue);
    event WithdrawFeeUpdated(uint256 newWithdrawFee);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeV2(uint256 _taxaInicial) public reinitializer(2) {     
        __ReentrancyGuard_init();   
        withdrawFee = _taxaInicial;
    }

    function deposit() public payable {
        require(msg.value > 0, "O valor do deposito deve ser maior que zero");
        balance[msg.sender] += msg.value;
        emit DepositMade(msg.sender, msg.value);
    }

    function withdraw(uint256 _valueRequested) public nonReentrant {
        require(_valueRequested > 0, "Hm... ta brincando comigo ne?... saldo tem que ser maior que ZERO rapaz!!!");
        require(balance[msg.sender] >= _valueRequested, "Ta... boa tentativa kkkk, voce nao tem saldo para isso amigao!");

        uint256 valueWithDiscount = _valueRequested;
        if (withdrawFee > 0) {
            require(_valueRequested > withdrawFee, "O saque nao cobre a taxa do banco");
            valueWithDiscount = _valueRequested - withdrawFee;
            totalWithdrawFeeCollected += withdrawFee;
        }

        balance[msg.sender] -= _valueRequested;
        (bool sucess, ) = payable(msg.sender).call{value: valueWithDiscount}("");
        require(sucess, "Falha ao enviar ether");

        emit WithdrawMade(msg.sender, valueWithDiscount);
    }

    function updateWithdrawFee(uint256 _newFee) public onlyOwner {
        withdrawFee = _newFee;
        emit WithdrawFeeUpdated(_newFee);
    }

    function getWithdrawFee() public view returns (uint256) {
        return withdrawFee;
    }

    function getWithdrawFeeCollected() public view onlyOwner returns (uint256) {
        return totalWithdrawFeeCollected;
    }

    function getAccountBalance(address _account) public view returns (uint256) {
        return balance[_account];
    }

    function withdrawFeeAdmin() public onlyOwner {
        uint256 fee = totalWithdrawFeeCollected;
        require(fee > 0, "Nenhum lucro para sacar");
        
        totalWithdrawFeeCollected = 0;
        
        (bool sucess, ) = payable(owner()).call{value: fee}("");
        require(sucess, "Falha ao enviar os lucros");
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}