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

    mapping(string=>uint256) internal MineralPrices;
    mapping(string=>address) internal MineralPricesOracle;
    mapping(address=>mapping(string=>mapping(string=>uint256))) internal newHoldings;
    mapping(address => bool) public excludedFromFees;

    struct Holdings {
        address owner;
        string assetIpfsCID;
        string mineralSymbol;
        uint256 ounces;
    }

    Holdings[] internal newHoldingArray;
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

        // Initialize mineralSymbols with default symbols
        mineralSymbols.push("CU");
        MineralPricesOracle["CU"] = address(0);
        MineralPrices["CU"] = 10000; //default value for copper over from existing holdings

        mineralSymbols.push("AU");
        MineralPrices["AU"] = 215544000000; //Gold spot price at time of published

        mineralSymbols.push("GR");
        MineralPricesOracle["GR"] = address(0);
        MineralPrices["GR"] = 10000000;  //default value since porting over existing Holdings

        mineralSymbols.push("BA");
        MineralPricesOracle["BA"] = address(0);
        mineralSymbols.push("CH");
        MineralPricesOracle["CH"] = address(0);
        mineralSymbols.push("CL");
        MineralPricesOracle["CL"] = address(0);
        mineralSymbols.push("CB");
        MineralPricesOracle["CB"] = address(0);
        mineralSymbols.push("DM");
        MineralPricesOracle["DM"] = address(0);
        mineralSymbols.push("ID");
        MineralPricesOracle["ID"] = address(0);
        mineralSymbols.push("IR");
        MineralPricesOracle["IR"] = address(0);
        mineralSymbols.push("LT");
        MineralPricesOracle["LT"] = address(0);
        mineralSymbols.push("MS");
        MineralPricesOracle["MS"] = address(0);
        mineralSymbols.push("MG");
        MineralPricesOracle["MG"] = address(0);
        mineralSymbols.push("NK");
        MineralPricesOracle["NK"] = address(0);
        mineralSymbols.push("OI");
        MineralPricesOracle["OI"] = address(0);
        mineralSymbols.push("OS");
        MineralPricesOracle["OS"] = address(0);
        mineralSymbols.push("PD");
        MineralPricesOracle["PD"] = address(0);
        mineralSymbols.push("PT");
        MineralPricesOracle["PT"] = address(0);
        mineralSymbols.push("RD");
        MineralPricesOracle["RD"] = address(0);
        mineralSymbols.push("RT");
        MineralPricesOracle["RT"] = address(0);
        mineralSymbols.push("SL");
        MineralPricesOracle["SL"] = address(0);
        mineralSymbols.push("TZ");
        MineralPricesOracle["TZ"] = address(0);
        mineralSymbols.push("TG");
        MineralPricesOracle["TG"] = address(0);

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
        unchecked {
            ++newHoldingIndex;
        }


        // Calculation logic
        uint256 mineralValueInWei = calculateMineralValueInWei(
            mineralSymbol,
            mineralOunces
        );

        // Calculate tokens to mint
        uint256 tokensToMintInWei = computeTokenByWei(mineralValueInWei);

        // Calculate admin fee
        uint256 adminFeeInWei = calculateAdminFee(tokensToMintInWei);

        require(adminFeeInWei <= tokensToMintInWei, "Admin fee exceeds tokens to mint");

        // Calculate amount to transfer to Holding owner in Wei
        uint256 amountToTransferToHoldingOwner = tokensToMintInWei - adminFeeInWei;

        // Ensure that the amount to mint is greater than zero
        require(tokensToMintInWei > 0, "Tokens to mint > zero");
        require(amountToTransferToHoldingOwner > 0, "Owner mint NOT > 0");
        require(adminFeeInWei > 0, "Admin fee NOT > 0");

        // Update totalAssetValue
        totalAssetValue += mineralValueInWei;

        // Mint tokens directly to the Holding owner's wallet
        _mint(holdingOwner, amountToTransferToHoldingOwner);

        // Mint admin fee directly to the contract owner's wallet
        _mint(owner(), adminFeeInWei);

        _addMineralSymbol(mineralSymbol);

        updateAndComputeTokenPrice();
        // Events, etc...
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

        // to keep a list of these synthetic elements not on table. You might come up with a better solution.
        bool symbolExists;
        for (uint256 i; i < mineralSymbols.length; i++) {
            if (
                keccak256(bytes(mineralSymbols[i])) ==
                keccak256(bytes(mineralSymbol))
            ) {
                symbolExists = true;
                emit MineralSymbolNotAdded(mineralSymbol);
                break;
            }
        }
        if (!symbolExists) {
            mineralSymbols.push(mineralSymbol);
            emit MineralSymbolAdded(mineralSymbol);
        }

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

    function transfer(address to, uint256 amount) public override returns (bool) {
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

    event ExistingDataToHolding(address holdingOwner, string assetIpfsCID, string mineralSymbol, uint256 mineralOunces);
    event MineralSymbolAdded(string mineralSymbol);
    event MineralSymbolNotAdded(string mineralSymbol);

    event TokenPriceUpdated(uint256);

    event GasFeePercentageBpsUpdated(uint256 newGasFeePercentageBps);

    function getTokenValue() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0; // Avoid division by zero if totalSupply is zero
        }
        return (totalAssetValue * 1e18) / totalSupply();
    }

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


    function baseValue() public pure returns (uint256) {
        return 159089461098 * (10**18);
    }

    bool internal calledOnce;

}