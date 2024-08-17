// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @custom:security-contact security@mineral-token.com
contract MXTK is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable,
OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable, ReentrancyGuard {

    // Gas fee percentage in basis points (bps)
    uint256 public gasFeePercentageBps;

    mapping(string=>uint256) public MineralPrices;
    mapping(string=>address) public MineralPricesOracle;
    mapping(address=>mapping(string=>mapping(string=>uint256))) public newHoldings;
    mapping(address => bool) public excludedFromFees;

    struct Holdings {
        address owner;
        string assetIpfsCID;
        string mineralSymbol;
        uint256 ounces;
    }

    Holdings[] public newHoldingArray;
    uint256 internal newHoldingIndex;

    // Add this array to keep track of mineral symbols
    string[] public mineralSymbols;
    uint256 public totalAssetValue; // Total value of all assets in the contract

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __ERC20_init("Mineral Token", "MXTK");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(initialOwner);
        __ERC20Permit_init("Mineral Token");
        __UUPSUpgradeable_init();

        gasFeePercentageBps = 10; // Default to 10 bps (0.1%)

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function excludeFromFees(address account) external onlyOwner {
        excludedFromFees[account] = true;
    }

    function includeInFees(address account) external onlyOwner {
        excludedFromFees[account] = false;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value)
    internal
    override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        require(!frozenAccounts[from], "Sender account is frozen");
        require(!frozenAccounts[to], "Recipient account is frozen");
        super._update(from, to, value);
    }

    function updateMineralPriceOracle(string memory mineralSymbol,address priceOracleAddress, address ownerAddress) public {
        require(ownerAddress == owner(), "Only the contract owner can update the mineral price oracle");
        MineralPricesOracle[mineralSymbol]=priceOracleAddress;
    }

    // A holding can have N number of minerals inside of it.
    function existingDataToHolding(
        address holdingOwner,
        string memory assetIpfsCID,
        string memory mineralSymbol,
        uint256 mineralOunces
    ) internal onlyOwner{
        require(holdingOwner != address(0), "Holding not found");
        require(bytes(assetIpfsCID).length > 0 && bytes(assetIpfsCID).length <= 64, "Invalid IPFS CID");
        require(mineralOunces > 0 && mineralOunces <= 1e18, "Invalid mineral ounces");
        require(bytes(mineralSymbol).length > 0 && bytes(mineralSymbol).length < 6, "Symbol cannot be empty or > 6");

        // Check if the mineral already exists for this Holding or in originalMineralOunces
        require(
            newHoldings[holdingOwner][assetIpfsCID][mineralSymbol] == 0,
            "Mineral already exists"
        );


        newHoldings[holdingOwner][assetIpfsCID][mineralSymbol] = mineralOunces;

        Holdings memory tx1 = Holdings(holdingOwner,assetIpfsCID,mineralSymbol,mineralOunces);
        newHoldingArray.push(tx1);
        newHoldingIndex++;


        // Calculation logic
        uint256 mineralValueInWei = calculateMineralValueInWei(
            mineralSymbol,
            mineralOunces
        );

        // Update totalAssetValue
        totalAssetValue += mineralValueInWei;
        updateAndComputeTokenPrice();

        emit ExistingDataToHolding(holdingOwner,assetIpfsCID,mineralSymbol,mineralOunces);
    }

    function addMineralToHolding(
        address holdingOwner,
        string memory assetIpfsCID,
        string memory mineralSymbol,
        uint256 mineralOunces
    ) external onlyOwner {
        require(holdingOwner != address(0), "Error 1: Invalid holding owner address");
        require(bytes(assetIpfsCID).length > 0 && bytes(assetIpfsCID).length <= 64, "Error 2: Invalid IPFS CID length");
        require(mineralOunces > 0 && mineralOunces <= 1e18, "Error 3: Invalid mineral ounces");
        require(bytes(mineralSymbol).length > 0 && bytes(mineralSymbol).length < 6, "Error 4: Invalid mineral symbol length");

        // Check if the mineral already exists for this Holding
        require(
            newHoldings[holdingOwner][assetIpfsCID][mineralSymbol] == 0,
            "Error 5: Mineral already exists in this holding"
        );

        newHoldings[holdingOwner][assetIpfsCID][mineralSymbol] = mineralOunces;

        Holdings memory tx1 = Holdings(holdingOwner, assetIpfsCID, mineralSymbol, mineralOunces);
        newHoldingArray.push(tx1);
        unchecked {
            ++newHoldingIndex;
        }

        // Calculation logic
        uint256 mineralValueInWei = calculateMineralValueInWei(
            mineralSymbol,
            mineralOunces
        );
        require(mineralValueInWei > 0, "Error 6: Invalid mineral value");

        // Calculate tokens to mint
        uint256 tokensToMintInWei = computeTokenByWei(mineralValueInWei);
        require(tokensToMintInWei > 0, "Error 7: Invalid tokens to mint");

        // Calculate admin fee
        uint256 adminFeeInWei = calculateAdminFee(tokensToMintInWei);
        require(adminFeeInWei <= tokensToMintInWei, "Error 8: Admin fee exceeds tokens to mint");

        // Calculate amount to transfer to Holding owner in Wei
        uint256 amountToTransferToHoldingOwner = tokensToMintInWei - adminFeeInWei;
        require(amountToTransferToHoldingOwner > 0, "Error 9: Invalid amount to transfer to holding owner");

        // Update totalAssetValue
        totalAssetValue += mineralValueInWei;

        // Mint tokens directly to the Holding owner's wallet
        _mint(holdingOwner, amountToTransferToHoldingOwner);

        // Mint admin fee directly to the contract owner's wallet
        _mint(owner(), adminFeeInWei);

        // Check if the mineral symbol is already valid before adding it
        if (!validMinerals[mineralSymbol]) {
            _addMineralSymbol(mineralSymbol);
        }

        updateAndComputeTokenPrice();

        emit MineralAdded(
            holdingOwner,
            mineralSymbol,
            mineralOunces,
            mineralValueInWei,
            tokensToMintInWei,
            adminFeeInWei,
            amountToTransferToHoldingOwner
        );
    }

    // Function to update prices of underlying assets and compute token price
    function updateAndComputeTokenPrice() public {
        // Update the prices of underlying assets
        // Recalculate the total asset value and token price
        totalAssetValue = calculateTotalAssetValue();
        uint256 newTokenPrice = getTokenValue();

        // Emit an event or log the updated token price
        emit TokenPriceUpdated(newTokenPrice);
    }

    // Function to calculate the total value of all assets in the contract
    function calculateTotalAssetValue() internal view returns (uint256) {
        uint256 totalValue;

        for (uint256 i; i < newHoldingArray.length;) {
            totalValue += calculateMineralValueInWei(newHoldingArray[i].mineralSymbol, newHoldingArray[i].ounces);
            unchecked {
                ++i;
            }
        }

        return totalValue;
    }

    function _addMineralSymbol(string memory mineralSymbol) internal {
        require(!validMinerals[mineralSymbol], "Mineral symbol already exists");
        mineralSymbols.push(mineralSymbol);
        validMinerals[mineralSymbol] = true;
        emit MineralSymbolAdded(mineralSymbol);
    }

    // Function to add a mineral symbol to the array
    function addMineralSymbol(string memory mineralSymbol) external onlyOwner{
        _addMineralSymbol(mineralSymbol);
    }


    // Function to calculate the number of tokens to burn based on Holding value
    function computeTokenByWei(uint256 weiAmount)
    public
    view
    returns (uint256)
    {
        require(weiAmount > 0, "Value must > zero");

        uint256 price = getTokenValue();

        //When porting data the first time; we'll have a value of zero. We'll use
        // the original value when minting tokens
        if(price == 0)
            price = baseValue();

        // Calculate tokens to burn
        uint256 tokens = divide(weiAmount, price);

        return tokens;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "division by zero will result in infinity.");
        return (a * 1e18) / b;
    }

    //Price paid by mineral owners to Mineral Token for our services
    function calculateAdminFee(uint256 tokensToMintInWei)
    public
    pure
    returns (uint256)
    {
        require(tokensToMintInWei > 0, "Fee must > zero");
        return (tokensToMintInWei * 40) / 100;
    }

    // Function to calculate the value of a mineral based on its symbol and ounces
    function calculateMineralValueInWei(
        string memory mineralSymbol,
        uint256 mineralOunces
    ) public view returns (uint256) {
        uint256 mineralPrice = getMineralPrice(mineralSymbol);
        return divide(mineralPrice * mineralOunces, 10**8);
    }

    function getMineralPrice(string memory mineralSymbol) public view returns (uint256) {
        int256 price;
        AggregatorV3Interface tx1 = AggregatorV3Interface(MineralPricesOracle[mineralSymbol]);
        (, price, , , ) = tx1.latestRoundData();

        return uint256(price);

    }

    function mintReimbursement(address to, uint256 amount) external onlyOwner {
        require(!frozenAccounts[to], "Cannot mint to a frozen account");
        _mint(to, amount);
        emit ReimbursementMinted(to, amount);
    }

    // Function to check if a mineral symbol is valid
    function isMineralValid(string memory mineralSymbol) public view returns (bool) {
        bool isValid = validMinerals[mineralSymbol];
        return isValid;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(!frozenAccounts[msg.sender], "Sender account is frozen");
        require(!frozenAccounts[to], "Recipient account is frozen");

        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must > zero");

        // Get balance before transfer
        uint256 balanceBefore = balanceOf(msg.sender);

        uint256 gasFee = 0;
        if (!excludedFromFees[msg.sender]) {
            // Calculate gas fee based on amount - gasFee
            // This avoids double charging fee on the fee
            gasFee = (amount * gasFeePercentageBps) / 10_000;
        }

        // Check balance is sufficient before any transfer
        require(balanceBefore >= amount, "Insufficient balance");

        // Ensure that the calculated gasFee does not exceed the amount
        require(gasFee < amount, "Gas fee exceeds amount");

        // Transfer tokens minus gas fee
        require(super.transfer(to, amount - gasFee), "Transfer failed");

        if (gasFee > 0) {
            // Transfer gas fee to owner
            require(super.transfer(owner(), gasFee), "Gas fee transfer failed");
        }

        return true;
    }

    // Function to allow the Holding owner to "buy back" their Holding
    function buyBackHolding(address holdingOwner,string memory ipfsCID) external onlyOwner nonReentrant{
        // Calculate the current value of the minerals in the Holding
        uint256 holdingValueInWei = calculateHoldingValueInWei(
            holdingOwner, ipfsCID
        );

        // Ensure that the Holding value is greater than zero
        require(holdingValueInWei > 0, "Holding has no value");

        // Calculate the number of tokens to burn based on Holding value
        uint256 tokensToBurn = computeTokenByWei(holdingValueInWei);

        // Ensure that the Holding owner has enough tokens for the buyback
        require(
            balanceOf(holdingOwner) >= tokensToBurn,
            "Insufficient tokens for buyback"
        );

        // Burn the tokens
        _burn(holdingOwner, tokensToBurn);

        // Remove the holding from the owner
        removeHoldingFromOwner(holdingOwner, ipfsCID);

        // Emit an event to log the Holding buyback
        emit HoldingBuyback(holdingOwner, tokensToBurn, holdingValueInWei);
    }

    // Function to remove the holding from the owner
    function removeHoldingFromOwner(address holdingOwner, string memory ipfsCid) internal {
        for (uint256 i; i < newHoldingArray.length;) {
            if (newHoldingArray[i].owner == holdingOwner &&
                keccak256(bytes(newHoldingArray[i].assetIpfsCID)) == keccak256(bytes(ipfsCid))
            ) {
                // Remove the holding by swapping with the last element and then reducing the array length
                newHoldingArray[i] = newHoldingArray[newHoldingArray.length - 1];
                delete newHoldingArray[newHoldingArray.length - 1];
                newHoldingArray.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    // Function to calculate the value of minerals in the Holding
    function calculateHoldingValueInWei(
        address holdingOwner,
        string memory ipfsCid
    ) public view returns (uint256) {

        uint256 totalHoldingValue;

        // Calculate the value of each mineral in the Holding
        for (uint256 i; i < newHoldingArray.length;) {
            if (newHoldingArray[i].owner == holdingOwner &&
                keccak256(bytes(newHoldingArray[i].assetIpfsCID)) == keccak256(bytes(ipfsCid))
            ) {
                totalHoldingValue += calculateMineralValueInWei(
                    newHoldingArray[i].mineralSymbol,
                    newHoldingArray[i].ounces
                );
            }
            unchecked {
                ++i;
            }
        }

        return totalHoldingValue;
    }

    // Function to update the gas fee percentage
    function setGasFeePercentageBps(uint256 _gasFeePercentageBps) external onlyOwner {
        require(_gasFeePercentageBps <= 1000, "Gas fee percentage must be less than or equal to 1000 bps (10%)");

        gasFeePercentageBps = _gasFeePercentageBps;
        emit GasFeePercentageBpsUpdated(_gasFeePercentageBps);
    }

    // Override transferFrom function to check for frozen accounts
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!frozenAccounts[from], "Sender account is frozen");
        require(!frozenAccounts[to], "Recipient account is frozen");
        return super.transferFrom(from, to, amount);
    }

    // Function to freeze/unfreeze an account
    function _setAccountFrozen(address account, bool frozen) internal onlyOwner {
        frozenAccounts[account] = frozen;
        emit AccountFrozen(account, frozen);
    }

    function setAccountFrozen(address account, bool frozen) external onlyOwner {
        _setAccountFrozen(account,frozen);
    }

    // function to see if account is frozen
    function isAccountFrozen(address account) public view returns (bool) {
        return frozenAccounts[account];
    }

    // Function to burn tokens from an account that can't buy them back
    function forceBurn(address account, uint256 amount) external onlyOwner {
        require(balanceOf(account) >= amount, "Insufficient balance to burn");
        _burn(account, amount);
        emit ForcedBurn(account, amount);
    }

    function getTokenValue() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0; // Avoid division by zero if totalSupply is zero
        }
        return (totalAssetValue * 1e18) / totalSupply();
    }

    event ExistingDataToHolding(address holdingOwner, string assetIpfsCID, string mineralSymbol, uint256 mineralOunces);
    event MineralSymbolAdded(string mineralSymbol);
    event MineralSymbolNotAdded(string mineralSymbol);
    event TokenPriceUpdated(uint256);
    event GasFeePercentageBpsUpdated(uint256 newGasFeePercentageBps);

    // Event to log Holding release
    event HoldingBuyback(
        address indexed sender,
        uint256 tokensToBurn,
        uint256 holdingValueInWei
    );

    event MineralAdded(
        address indexed holdingOwner,
        string mineralSymbol,
        uint256 mineralOunces,
        uint256 mineralValue,
        uint256 tokensMinted,
        uint256 adminFee,
        uint256 amountTransferredToHoldingOwner
    );

    event AccountFrozen(address indexed account, bool frozen);
    event ForcedBurn(address indexed account, uint256 amount);
    event ReimbursementMinted(address indexed to, uint256 amount);
    event MineralAdded(string mineralSymbol);
    event InitializationComplete();
    event MineralValidationChecked(string mineralSymbol, bool isValid);


    function baseValue() public pure returns (uint256) {
        return 159089461098 * (10**18);
    }

    function initNewVars() public onlyOwner{
        require(!isInitialized,"already added new minerals");
        string[174] memory elements = [
            // Periodic Table Elements (1-118)
                    "H", "HE", "LI", "BE", "B", "C", "N", "O", "F", "NE",
                    "NA", "MG", "AL", "SI", "P", "S", "CL", "AR", "K", "CA",
                    "SC", "TI", "V", "CR", "MN", "FE", "CO", "NI", "CU", "ZN",
                    "GA", "GE", "AS", "SE", "BR", "KR", "RB", "SR", "Y", "ZR",
                    "NB", "MO", "TC", "RU", "RH", "PD", "AG", "CD", "IN", "SN",
                    "SB", "TE", "I", "XE", "CS", "BA", "LA", "CE", "PR", "ND",
                    "PM", "SM", "EU", "GD", "TB", "DY", "HO", "ER", "TM", "YB",
                    "LU", "HF", "TA", "W", "RE", "OS", "IR", "PT", "AU", "HG",
                    "TL", "PB", "BI", "PO", "AT", "RN", "FR", "RA", "AC", "TH",
                    "PA", "U", "NP", "PU", "AM", "CM", "BK", "CF", "ES", "FM",
                    "MD", "NO", "LR", "RF", "DB", "SG", "BH", "HS", "MT", "DS",
                    "RG", "CN", "NH", "FL", "MC", "LV", "TS", "OG",

            // Crude Oil and Byproducts
                    "CRUD", "NGAS", "GSLN", "KERO", "DIES", "FOIL", "NAPH", "PROP", "BUTA", "LUBE", "ASPL",

            // Rare Earth Elements (some overlap with periodic table, but included for emphasis)
                    "SC", "Y", "LA", "CE", "PR", "ND", "PM", "SM", "EU", "GD", "TB", "DY", "HO", "ER", "TM", "YB", "LU",

            // Other commercially important minerals and materials
                    "GR", "DMND", "RLBY", "SPPHR", "EMRLD", "TPAZ", "OPAL", "QRTZ", "MICA", "FLSP", "CLCT", "DLMT", "GYPS",
                    "TLCM", "ZRCN", "APAT", "FLUOR", "BRYL", "PYRX", "AMPH", "OLIV", "GRNT",

            // Additional commodities
                    "RVSND", "COAL", "IRON", "BAUXITE", "PHOSPHATE", "LIMST"
            ];

        uint256 defaultPrice = 0;
        address defaultOracle = address(0);

        for (uint i = 0; i < elements.length; i++) {
            string memory element = elements[i];
            mineralSymbols.push(element);
            MineralPricesOracle[element] = defaultOracle;
            MineralPrices[element] = defaultPrice;
            validMinerals[element] = true;
            emit MineralAdded(element); // Add this event
        }

        MineralPrices["CU"] = 10000;
        MineralPrices["AU"] = 215544000000;
        MineralPrices["GR"] = 10000000;

        isInitialized = true;
        emit InitializationComplete(); // Add this event
    }

    bool internal calledOnce;
    // New state variables
    mapping(address => bool) public frozenAccounts;
    mapping(string => bool) public validMinerals;
    bool public isInitialized;

}