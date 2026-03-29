// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// ========================================================================
// CUSTOM ERRORS V5
// ========================================================================
error AccountAlreadyApproved(address user);
error AgeNotAllowed(uint256 currentAge, uint256 minimumAge);
error InvalidEmptyField();
error InvalidAmount();
error InsufficientBalance(uint256 requested, uint256 available);
error AmountDoesNotCoverFee(uint256 requested, uint256 fee);
error TransferFailed();
error NoProfitsToWithdraw();

contract BankV5BETA is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    
    // V1
    mapping(address => uint256) public balance;

    // V2
    uint256 public withdrawFee;
    uint256 public totalWithdrawFeeCollected;
    uint256 private _status;

    // V3
    bool public isPaused;

    // V4
    mapping(address => bool) public isWhitelisted;

    //STRUCT TEMPORARIA
    struct Register {
        string name;
        uint256 age;
        string country;
    }

    // EVENTOS
    event DepositMade(address indexed user, uint256 cashValue);
    event WithdrawMade(address indexed user, uint256 cashValue);
    event WithdrawFeeUpdated(uint256 newWithdrawFee);
    event Paused(address account);
    event Unpaused(address account);

    // CONSTRUTOR/INICIANILAZORES
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @custom:oz-upgrades-validate-as-initializer
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

    // MODIFICADORES
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

    modifier onlyRegistered() {
        require(isWhitelisted[msg.sender], "Acesso negado: Faca seu cadastro primeiro!");
        _;
    }

    // FUNCOES DE USUARIOS/PUBLIC
    function registerRequest(string memory _name, uint256 _age, string memory _country) public {
        if (isWhitelisted[msg.sender]) {
            revert AccountAlreadyApproved(msg.sender);
        }

        Register memory registerTemp = Register(_name, _age, _country);

        if (registerTemp.age < 18) {
            revert AgeNotAllowed({
                currentAge: registerTemp.age, 
                minimumAge: 18
            });
        }

        if (bytes(registerTemp.name).length == 0) {
            revert InvalidEmptyField();
        }
        
        if (bytes(registerTemp.country).length == 0) {
            revert InvalidEmptyField();
        }

        isWhitelisted[msg.sender] = true;
    }

    function deposit() public payable whenNotPaused onlyRegistered {
        if (msg.value == 0) {
            revert InvalidAmount();
        }
        balance[msg.sender] += msg.value;
        emit DepositMade(msg.sender, msg.value);
    }

    function withdraw(uint256 _valueRequested) public nonReentrant whenNotPaused onlyRegistered {
        if (_valueRequested == 0) {
            revert InvalidAmount();
        }

        if (balance[msg.sender] < _valueRequested) {
            revert InsufficientBalance({
                requested: _valueRequested, 
                available: balance[msg.sender]
            });
        }

        uint256 valueWithDiscount = _valueRequested;
        if (withdrawFee > 0) {
            if (_valueRequested <= withdrawFee) {
                revert AmountDoesNotCoverFee({
                    requested: _valueRequested, 
                    fee: withdrawFee
                });
            }
            valueWithDiscount = _valueRequested - withdrawFee;
            totalWithdrawFeeCollected += withdrawFee;
        }

        balance[msg.sender] -= _valueRequested;
        
        (bool sucess, ) = payable(msg.sender).call{value: valueWithDiscount}("");
        if (!sucess) {
            revert TransferFailed();
        }

        emit WithdrawMade(msg.sender, valueWithDiscount);
    }

    function getWithdrawFee() public view returns (uint256) {
        return withdrawFee;
    }

    function getAccountBalance(address _account) public view returns (uint256) {
        return balance[_account];
    }

    // FUNCOES DE ADMINISTRACAO
    function breakContract() public onlyOwner {
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unBreakContract() public onlyOwner {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function updateWithdrawFee(uint256 _newFee) public onlyOwner {
        withdrawFee = _newFee;
        emit WithdrawFeeUpdated(_newFee);
    }

    function getWithdrawFeeCollected() public view onlyOwner returns (uint256) {
        return totalWithdrawFeeCollected;
    }

    function withdrawFeeAdmin() public onlyOwner {
        uint256 fee = totalWithdrawFeeCollected;
        
        if (fee == 0) {
            revert NoProfitsToWithdraw();
        }
        
        totalWithdrawFeeCollected = 0;
        
        (bool sucess, ) = payable(owner()).call{value: fee}("");
        if (!sucess) {
            revert TransferFailed();
        }
    }

    function blockAccount(address _account) public onlyOwner {
        isWhitelisted[_account] = false;
    }

    function approveAccount(address _account) public onlyOwner {
        isWhitelisted[_account] = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}