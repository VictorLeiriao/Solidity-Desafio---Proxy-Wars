// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ========================================================================
// CUSTOM ERRORS (V8)
// ========================================================================
error AccountAlreadyApproved(address user);
error AccountBlocked(address user);
error AccountNotRegistered(address user);
error AgeNotAllowed(uint256 currentAge, uint256 minimumAge);
error InvalidEmptyField();
error InvalidAmount();
error InsufficientBalance(uint256 requested, uint256 available);
error AmountTooLow();
error InvalidFee();
error TransferFailed();
error NoProfitsToWithdraw();
error TokenInsufficientLiquidity(uint256 requested, uint256 available);
error PolInsufficientLiquidity(uint256 requested, uint256 available);
error ReentrantCall();
error ContractIsPaused();

// ========================================================================
// CUSTOM ERRORS (V9 - NFT Marketplace)
// ========================================================================
error InvalidPrice();
error ListingNotActive(uint256 listingId);
error WrongPayment(uint256 sent, uint256 expected);
error InvalidCollection();

contract BankV9 is Initializable, UUPSUpgradeable, OwnableUpgradeable, ERC721Holder {
    using SafeERC20 for IERC20;

    // ========================================================================
    // STORAGE (MUST MATCH BankV8 ORDER)
    // ========================================================================

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

    // V5 & V6 (DEX)
    IERC20 public tokenExchange;
    uint256 public feeExchange;
    uint256 public liquidityPOL;

    struct Register {
        string name;
        uint256 age;
        string country;
    }

    // V7 (FICHA SUJA / BANIDOS)
    mapping(address => bool) public isBlocked;

    // ========================================================================
    // V9 - NFT MARKETPLACE (ESCROW NO PROXY)
    // ========================================================================
    struct NftListing {
        address collection;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    uint256 public nextListingId;
    mapping(uint256 => NftListing) public listings;

    // NOTE: V8 had uint256[50] __gap; we consumed 2 storage slots above.
    uint256[48] private __gap;

    // ========================================================================
    // EVENTS (V8 + V9)
    // ========================================================================
    event DepositMade(address indexed user, uint256 cashValue);
    event WithdrawMade(address indexed user, uint256 cashValue);
    event WithdrawFeeUpdated(uint256 newWithdrawFee);
    event Paused(address account);
    event Unpaused(address account);

    event LiquidityPolAdd(uint256 value);
    event LiquidityTokenAdd(uint256 value);
    event TokenBuy(address indexed client, uint256 polOutGoing, uint256 tokensReceived);
    event TokenSell(address indexed client, uint256 tokensOutGoing, uint256 polReceived);
    event FeeExchangeUpdated(uint256 newFeeExchange);

    event NftListed(uint256 indexed listingId, address indexed collection, uint256 indexed tokenId, uint256 price);
    event NftListingCancelled(uint256 indexed listingId);
    event NftSold(uint256 indexed listingId, address indexed buyer, uint256 price);

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

    function initializeV9() public reinitializer(9) {
        // ERC721Holder não possui storage nem inicialização (é seguro para proxy).
    }

    // ========================================================================
    // MODIFIERS
    // ========================================================================
    modifier nonReentrant() {
        if (_status == 2) {
            revert ReentrantCall();
        }
        _status = 2;
        _;
        _status = 1;
    }

    modifier whenNotPaused() {
        if (isPaused) {
            revert ContractIsPaused();
        }
        _;
    }

    modifier onlyRegistered() {
        if (!isWhitelisted[msg.sender]) {
            revert AccountNotRegistered(msg.sender);
        }
        _;
    }

    // ========================================================================
    // CONTA CORRENTE
    // ========================================================================
    function registerRequest(string memory _name, uint256 _age, string memory _country) public {
        if (isBlocked[msg.sender]) {
            revert AccountBlocked(msg.sender);
        }
        if (isWhitelisted[msg.sender]) {
            revert AccountAlreadyApproved(msg.sender);
        }

        Register memory registerTemp = Register(_name, _age, _country);

        if (registerTemp.age < 18) {
            revert AgeNotAllowed({currentAge: registerTemp.age, minimumAge: 18});
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

    function withdraw(uint256 _valueRequested) public nonReentrant whenNotPaused {
        if (_valueRequested == 0) {
            revert InvalidAmount();
        }
        if (balance[msg.sender] < _valueRequested) {
            revert InsufficientBalance({requested: _valueRequested, available: balance[msg.sender]});
        }

        uint256 fee = (_valueRequested * withdrawFee) / 10000;
        uint256 valueWithDiscount = _valueRequested - fee;

        if (fee > 0) {
            totalWithdrawFeeCollected += fee;
        }

        balance[msg.sender] -= _valueRequested;

        (bool sucess,) = payable(msg.sender).call{value: valueWithDiscount}("");
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

    // ========================================================================
    // DEX (CÂMBIO)
    // ========================================================================
    function buyToken() public payable whenNotPaused onlyRegistered nonReentrant {
        if (msg.value == 0) {
            revert InvalidAmount();
        }

        uint256 amountTokens = msg.value * feeExchange;
        uint256 stockTokens = tokenExchange.balanceOf(address(this));

        if (stockTokens < amountTokens) {
            revert TokenInsufficientLiquidity(amountTokens, stockTokens);
        }

        liquidityPOL += msg.value;

        tokenExchange.safeTransfer(msg.sender, amountTokens);

        emit TokenBuy(msg.sender, msg.value, amountTokens);
    }

    function sellToken(uint256 _amountTokens) public whenNotPaused onlyRegistered nonReentrant {
        if (_amountTokens == 0) {
            revert InvalidAmount();
        }

        uint256 polOfPay = _amountTokens / feeExchange;
        if (polOfPay == 0) {
            revert AmountTooLow();
        }

        if (liquidityPOL < polOfPay) {
            revert PolInsufficientLiquidity(polOfPay, liquidityPOL);
        }

        liquidityPOL -= polOfPay;

        tokenExchange.safeTransferFrom(msg.sender, address(this), _amountTokens);

        (bool sucessoPol,) = payable(msg.sender).call{value: polOfPay}("");
        if (!sucessoPol) {
            revert TransferFailed();
        }

        emit TokenSell(msg.sender, _amountTokens, polOfPay);
    }

    function getStockTokens() public view returns (uint256) {
        return tokenExchange.balanceOf(address(this));
    }

    // ========================================================================
    // NFT MARKETPLACE (ESCROW NO PROXY)
    // ========================================================================
    function listNft(address collection, uint256 tokenId, uint256 price) external onlyOwner whenNotPaused {
        if (collection == address(0)) {
            revert InvalidCollection();
        }
        if (price == 0) {
            revert InvalidPrice();
        }

        uint256 id = nextListingId;
        unchecked {
            nextListingId = id + 1;
        }

        listings[id] = NftListing({collection: collection, tokenId: tokenId, price: price, active: true});

        // escrow: owner() → proxy
        IERC721(collection).safeTransferFrom(owner(), address(this), tokenId);

        emit NftListed(id, collection, tokenId, price);
    }

    function cancelListing(uint256 id) external onlyOwner {
        NftListing storage l = listings[id];
        if (!l.active) {
            revert ListingNotActive(id);
        }

        l.active = false;
        IERC721(l.collection).safeTransferFrom(address(this), owner(), l.tokenId);

        emit NftListingCancelled(id);
    }

    function buy(uint256 id) external payable whenNotPaused onlyRegistered nonReentrant {
        NftListing storage l = listings[id];
        if (!l.active) {
            revert ListingNotActive(id);
        }
        if (msg.value != l.price) {
            revert WrongPayment(msg.value, l.price);
        }

        l.active = false;

        // transfer NFT first; revert will roll back state if ERC721 reverts
        IERC721(l.collection).safeTransferFrom(address(this), msg.sender, l.tokenId);

        // pay owner
        (bool success,) = payable(owner()).call{value: msg.value}("");
        if (!success) {
            revert TransferFailed();
        }

        emit NftSold(id, msg.sender, msg.value);
    }

    // ========================================================================
    // ADMINISTRAÇÃO DA DEX (Apenas Dono)
    // ========================================================================
    function updateFeeExchange(uint256 _newFeeExchange) public onlyOwner {
        if (_newFeeExchange == 0) {
            revert InvalidFee();
        }
        feeExchange = _newFeeExchange;
        emit FeeExchangeUpdated(_newFeeExchange);
    }

    function updateTokenExchange(address _newTokenAddress) public onlyOwner {
        tokenExchange = IERC20(_newTokenAddress);
    }

    function addLiquidityPOL() public payable onlyOwner {
        if (msg.value == 0) {
            revert InvalidAmount();
        }
        liquidityPOL += msg.value;
        emit LiquidityPolAdd(msg.value);
    }

    function addLiquidityToken(uint256 _amount) public onlyOwner {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        tokenExchange.safeTransferFrom(msg.sender, address(this), _amount);
        emit LiquidityTokenAdd(_amount);
    }

    function removeLiquidityPOL(uint256 _amount) public onlyOwner {
        if (liquidityPOL < _amount) {
            revert PolInsufficientLiquidity(_amount, liquidityPOL);
        }
        liquidityPOL -= _amount;
        (bool sucesso,) = payable(owner()).call{value: _amount}("");
        if (!sucesso) {
            revert TransferFailed();
        }
    }

    function removeLiquidityToken(uint256 _amount) public onlyOwner {
        uint256 estoque = getStockTokens();
        if (estoque < _amount) {
            revert TokenInsufficientLiquidity(_amount, estoque);
        }
        tokenExchange.safeTransfer(owner(), _amount);
    }

    // ========================================================================
    // ADMINISTRAÇÃO GERAL
    // ========================================================================
    function breakContract() public onlyOwner {
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unBreakContract() public onlyOwner {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function updateWithdrawFee(uint256 _newFee) public onlyOwner {
        if (_newFee > 10000) {
            revert InvalidFee();
        }
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

        (bool sucess,) = payable(owner()).call{value: fee}("");
        if (!sucess) {
            revert TransferFailed();
        }
    }

    function blockAccount(address _account) public onlyOwner {
        isWhitelisted[_account] = false;
        isBlocked[_account] = true;
    }

    function approveAccount(address _account) public onlyOwner {
        isWhitelisted[_account] = true;
        isBlocked[_account] = false;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

