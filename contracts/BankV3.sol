// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BankV3 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    

    // V1
    mapping(address => uint256) public balance;

    // V2
    uint256 public withdrawFee;
    uint256 public totalWithdrawFeeCollected;
    uint256 private _status; 

    // V3
    bool public isPaused;

    event DepositMade(address indexed user, uint256 cashValue);
    event WithdrawMade(address indexed user, uint256 cashValue);
    event WithdrawFeeUpdated(uint256 newWithdrawFee);
    event Paused(address account);
    event Unpaused(address account);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    function initializeV2(uint256 _taxaInicial) public reinitializer(2) {     
        withdrawFee = _taxaInicial;
        _status = 1;
    }

    function initializeV3() public reinitializer(3) {
        isPaused = false;
    }

    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2; // Tranca
        _;
        _status = 1; // Destranca
    }

    modifier whenNotPaused() {
        require(!isPaused, "EMERGENCIA: O banco esta pausado! Movimentacoes bloqueadas.");
        _;
    }

    function breakContract() public onlyOwner {
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unBreakContract() public onlyOwner {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "O valor do deposito deve ser maior que zero");
        balance[msg.sender] += msg.value;
        emit DepositMade(msg.sender, msg.value);
    }

    function withdraw(uint256 _valueRequested) public nonReentrant whenNotPaused {
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