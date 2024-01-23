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
import {GraphitePriceOracle} from "./GraphitePriceOracle.sol";
import {CopperPriceOracle} from "./CopperPriceOracle.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

//TODO: We'll need to migrate the old contract data and tokens to this new contract
//TODO: We'll need to test that the Upgradable is working as expected on UniSwap
//TODO: We'll need an external code that monitors when prices event changes on the oracle and update the token price

contract MXTN is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable,
            OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    AggregatorV3Interface internal ethPriceFeed; // Chainlink ETH/USD Price Feed contract
    AggregatorV3Interface internal auPriceFeed; // Chainlink Gold Price Feed contract
    AggregatorV3Interface internal bauxitePriceFeed;
    AggregatorV3Interface internal chromiumPriceFeed;
    AggregatorV3Interface internal coalPriceFeed;
    AggregatorV3Interface internal cobaltPriceFeed;
    AggregatorV3Interface internal copperPriceFeed;
    AggregatorV3Interface internal diamondPriceFeed;
    AggregatorV3Interface internal graphitePriceFeed;
    AggregatorV3Interface internal iridiumPriceFeed;
    AggregatorV3Interface internal ironPriceFeed;
    AggregatorV3Interface internal lithiumPriceFeed;
    AggregatorV3Interface internal magnesiumPriceFeed;
    AggregatorV3Interface internal manganesePriceFeed;
    AggregatorV3Interface internal nickelPriceFeed;
    AggregatorV3Interface internal oilPriceFeed;
    AggregatorV3Interface internal osmiumPriceFeed;
    AggregatorV3Interface internal palladiumPriceFeed;
    AggregatorV3Interface internal platinumPriceFeed;
    AggregatorV3Interface internal rhodiumPriceFeed;
    AggregatorV3Interface internal rutheniumPriceFeed;
    AggregatorV3Interface internal silverPriceFeed;
    AggregatorV3Interface internal tanzanitePriceFeed;
    AggregatorV3Interface internal tungstenPriceFeed;

    using EnumerableMap for EnumerableMap.AddressToUintMap;

    function initialize(address initialOwner) initializer public {
        __ERC20_init("Mineral Token", "MXTK")
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(initialOwner);
        __ERC20Permit_init("Mineral Token");
        __UUPSUpgradeable_init();

        gasFeePercentage = 70; // Default to 70 bps (0.7%)
        ethPriceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); //ETH/USD address
        auPriceFeed = AggregatorV3Interface(
            0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6
        ); //XAU/USD address

        // Initialize mineralSymbols with default symbols
        mineralSymbols.push("CU");
        mineralSymbols.push("AU");
        mineralSymbols.push("GR");
    }

    // Price oracles for metals
    GraphitePriceOracle public graphitePriceOracleAddress;
    CopperPriceOracle public copperPriceOracleAddress;

    // Gas fee percentage
    uint256 public gasFeePercentage;

    // Mapping of HOLDINGs to their respective owners
    // Mapping of HOLDINGs for each address using assetIpfsCID as the key
    mapping(address => mapping(string => HOLDING)) public holdings;

    //TODO: We might want to consider breaking down the holdings variable for performance reasons; examples below
    //EnumerableMap.AddressToUintMap private holdings;
    //HashMap.HashMap private holdings;

    // Struct to represent HOLDING details. Holdings can be
    // SKR, JRTOC, 83101, etc.
    struct HOLDING {
        address owner;
        string assetIpfsCID;
        mapping(string => Mineral) minerals; // Mapping of minerals inside the HOLDING
    }

    // Struct to represent mineral details.
    //TODO: Given that we'll now support Oil and Goal, we might want to use other unit types. Will want to test
    // if the uint256 can support big oil contracts.
    // than just ounces.
    struct Mineral {
        string symbol;
        uint256 ounces;
    }

    // Add this array to keep track of mineral symbols
    string[] public mineralSymbols;

    // Mapping to associate mineral details with each minted token
    mapping(uint256 => Mineral) public mineralDetails;

    uint256 public totalAssetValue; // Total value of all assets in the contract

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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

    //TODO: Might not be needed anymore
    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 amount
    // ) internal override(ERC20, ERC20Burnable) whenNotPaused {
    //     super._beforeTokenTransfer(from, to, amount);
    // }

    function updateETHPriceOracle(address ethOracleAddress) external onlyOwner {
        require(ethOracleAddress != address(0), "Invalid address");
        ethPriceFeed = AggregatorV3Interface(ethOracleAddress);
    }

    function updateGoldPriceOracle(address goldOracleAddress)
    external
    onlyOwner
    {
        require(goldOracleAddress != address(0), "Invalid address");
        auPriceFeed = AggregatorV3Interface(goldOracleAddress);
    }

    // Set the address of the Graphite price oracle
    function setGraphitePriceOracle(GraphitePriceOracle _oracleAddress)
    external
    onlyOwner
    {
        graphitePriceOracleAddress = _oracleAddress;
    }

    // Set the address of the Copper price oracle
    function setCopperPriceOracle(CopperPriceOracle _oracleAddress)
    external
    onlyOwner
    {
        copperPriceOracleAddress = _oracleAddress;
    }

    //TODO: Add the Update/Set Oracles for all the remaining Oracles

    // Function to add a new HOLDING
    function addHOLDING(address _holdingOwner, string memory _assetIpfsCID)
    external
    onlyOwner
    {
        require(holdings[_holdingOwner][_assetIpfsCID].owner == address(0), "HOLDING already exists");


        // Create a new HOLDING struct
        HOLDING storage newHOLDING = holdings[_holdingOwner][_assetIpfsCID];

        // Initialize the HOLDING struct with the provided data
        newHOLDING.assetIpfsCID = _assetIpfsCID;
        newHOLDING.owner = _holdingOwner;
    }

    ///A holding can have N number of minerals inside of it.
    function addMineralToHOLDING(
        address holdingOwner,
        string memory assetIpfsCID,
        string memory mineralSymbol,
        uint256 mineralOunces
    ) external onlyOwner {
        require(holdingOwner != address(0), "HOLDING not found");
        require(bytes(assetIpfsCID).length > 0, "CID cannot be empty");
        require(mineralOunces > 0, "Oz must be greater than zero");
        require(bytes(mineralSymbol).length > 0, "Symbol cannot be empty");

        // Access a specific HOLDING for an address using assetIpfsCID
        HOLDING storage holding = holdings[holdingOwner][assetIpfsCID];

        // Ensure that the HOLDING owner exists
        require(holding.owner != address(0), "HOLDING owner does not exist");

        // Check if the mineral already exists for this HOLDING
        require(
            holding.minerals[mineralSymbol].ounces == 0,
            "Mineral already exists"
        );

        // Add the mineral details to the HOLDING storage
        holding.minerals[mineralSymbol] = Mineral({
            symbol: mineralSymbol,
            ounces: mineralOunces
        });

        // Calculation logic

        uint256 mineralValueInWei = calculateMineralValueInWei(
            mineralSymbol,
            mineralOunces
        );

        // Calculate tokens to mint
        uint256 tokensToMintInWei = computeTokenToMintByWei(mineralValueInWei);

        // Calculate admin fee
        uint256 adminFeeInWei = calculateAdminFee(tokensToMintInWei);

        // Calculate amount to transfer to HOLDING owner in Wei
        uint256 amountToTransferToHOLDINGOwner = tokensToMintInWei - adminFeeInWei;

        // Ensure that the amount to mint is greater than zero
        require(tokensToMintInWei > 0, "Tokens to mint > zero");
        require(amountToTransferToHOLDINGOwner > 0, "Owner mint NOT > 0");
        require(adminFeeInWei > 0, "Admin fee NOT > 0");

        // Update totalAssetValue
        totalAssetValue += mineralValueInWei;

        // Mint tokens directly to the HOLDING owner's wallet
        _mint(holdingOwner, amountToTransferToHOLDINGOwner);

        // Mint admin fee directly to the contract owner's wallet
        _mint(owner(), adminFeeInWei);

        addMineralSymbol(mineralSymbol);

        // Events, etc...
        emit MineralAdded(
            holdingOwner,
            mineralSymbol,
            mineralOunces,
            mineralValueInWei,
            tokensToMintInWei,
            adminFeeInWei,
            amountToTransferToHOLDINGOwner
        );
    }

    // Function to update prices of underlying assets and compute token price
    function updateAndComputeTokenPrice(
        uint256 newGraphitePrice,
        uint256 newCopperPrice
    ) external onlyOwner {
        // Update the prices of underlying assets
        graphitePriceOracleAddress.setGraphitePrice(newGraphitePrice);
        copperPriceOracleAddress.setCopperPrice(newCopperPrice);

        // Recalculate the total asset value and token price
        totalAssetValue = calculateTotalAssetValue();
        uint256 newTokenPrice = computeTokenPrice();

        // Emit an event or log the updated token price
        emit TokenPriceUpdated(newTokenPrice);
    }

    // Function to calculate the total value of all assets in the contract
    function calculateTotalAssetValue() internal view returns (uint256) {
        uint256 totalValue = 0;

        // Get outer mapping keys
        address[] memory holdingOwners = holdings.keys();

        for (uint256 i = 0; i < holdingOwners.length; i++) {
            address holdingOwner = holdingOwners[i];
            string[] memory assetIpfsCIDs = holdings[holdingOwner].keys();

            for (uint256 j = 0; j < assetIpfsCIDs.length; j++) {
                string memory assetIpfsCID = assetIpfsCIDs[j];
                HOLDING storage holding = holdings[holdingOwner][assetIpfsCID];

                for (uint256 k = 0; k < mineralSymbols.length; k++) {
                    string memory mineralSymbol = mineralSymbols[k];

                    if (
                        holding.owner != address(0) &&
                        bytes(holding.minerals[mineralSymbol].symbol).length > 0
                    ) {
                        uint256 mineralValue = calculateMineralValueInWei(
                            holding.minerals[mineralSymbol].symbol,
                            holding.minerals[mineralSymbol].ounces
                        );

                        totalValue += mineralValue;
                    }
                }
            }
        }

        return totalValue;
    }

    // Function to compute the new token price based on total asset value
    function computeTokenPrice() internal view returns (uint256) {
        // Ensure that totalSupply() is greater than zero to avoid division by zero
        require(totalSupply() > 0, "Total supply must be greater than zero");

        // Calculate the new token price based on total asset value and total supply
        return totalAssetValue / totalSupply();
    }

    // Function to add a mineral symbol to the array
    function addMineralSymbol(string memory mineralSymbol) public onlyOwner {
        bool symbolExists = false;
        for (uint256 i = 0; i < mineralSymbols.length; i++) {
            if (
                keccak256(bytes(mineralSymbols[i])) ==
                keccak256(bytes(mineralSymbol))
            ) {
                symbolExists = true;
                break;
            }
        }
        if (!symbolExists) {
            mineralSymbols.push(mineralSymbol);
        }
    }

    function computeTokenToMintByWei(uint256 weiAmount)
    public
    view
    returns (uint256)
    {
        require(weiAmount > 0, "Value must > zero");

        //TODO: Could we run into an issue if the Price of ETH moves to much?

        uint256 price = getETHPrice();

        require(price > 0, "ETH must > zero");

        // Calculate token to mint
        uint256 tokensToMintInWei = divide(weiAmount, price);

        return tokensToMintInWei;
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
        //TODO: Add the ability to update the Fee
        return (tokensToMintInWei * 40) / 100;
    }

    // Function to calculate the value of a mineral based on its symbol and ounces
    function calculateMineralValueInWei(
        string memory mineralSymbol,
        uint256 mineralOunces
    ) public view returns (uint256) {
        // Call the appropriate oracle based on the mineral symbol
        if (keccak256(bytes(mineralSymbol)) == keccak256(bytes("CU"))) {
            return calculateCopperValue(mineralOunces);
        } else if (keccak256(bytes(mineralSymbol)) == keccak256(bytes("AU"))) {
            return calculateGoldValue(mineralOunces);
        } else if (keccak256(bytes(mineralSymbol)) == keccak256(bytes("GR"))) {
            return calculateGraphiteValue(mineralOunces);
        } else {
            revert("Unsupported mineral symbol");
        }
    }

    function getCopperPrice() public view returns (uint256) {
        // Access the copperPrice directly from the oracle contract
        uint256 price = copperPriceOracleAddress.copperPrice();
        require(price > 0, "Price feed error");

        return uint256(price);
    }

    // Function to calculate the value of Copper based on ounces from an oracle
    function calculateCopperValue(uint256 metalOunces)
    public
    view
    returns (uint256)
    {
        // Ensure that the copperPriceOracleAddress is set
        require(
            address(copperPriceOracleAddress) != address(0),
            "Copper oracle address not set"
        );

        uint256 copperPricePerOunce = getCopperPrice();
        return metalOunces * copperPricePerOunce;
    }

    function getETHPrice() public view returns (uint256) {
        // Get the latest ETH/USD price from Chainlink in 8 decimal position
        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        require(price > 0, "Price feed error");

        return uint256(price);
    }

    function getGoldPrice() public view returns (uint256) {
        (, int256 price, , , ) = auPriceFeed.latestRoundData();
        require(price > 0, "Price feed error");

        return uint256(price);
    }

    // Function to calculate the value of Gold based on ounces from an oracle
    function calculateGoldValue(uint256 metalOunces)
    public
    view
    returns (uint256)
    {
        uint256 price = getGoldPrice();
        //Gold is returned in
        return metalOunces * price;
    }

    function getGraphitePrice() public view returns (uint256) {
        uint256 price = graphitePriceOracleAddress.graphitePrice();
        require(price > 0, "Price feed error");

        return uint256(price);
    }

    // Function to calculate the value of Graphite based on ounces from an oracle
    function calculateGraphiteValue(uint256 metalOunces)
    public
    view
    returns (uint256)
    {
        // Ensure that the graphitePriceOracleAddress is set
        require(
            address(graphitePriceOracleAddress) != address(0),
            "Graphite oracle address not set"
        );

        uint256 graphitePricePerOunce = getGraphitePrice();

        // Calculate the value based on the retrieved graphitePrice and metal ounces
        return metalOunces * graphitePricePerOunce;
    }

    function transfer(address to, uint256 amount)
    public
    override
    returns (bool)
    {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must > zero");

        // Get balance before transfer
        uint256 balanceBefore = balanceOf(msg.sender);

        // Calculate gas fee based on amount - gasFee
        // This avoids double charging fee on the fee
        uint256 gasFee = (amount * gasFeePercentage) / 10_000;

        // Check balance is sufficient before any transfer
        require(balanceBefore >= amount, "Insufficient balance");

        // Ensure that the calculated gasFee does not exceed the amount
        require(gasFee < amount, "Gas fee exceeds amount");

        // Transfer tokens minus gas fee
        super.transfer(to, amount - gasFee);

        // Transfer gas fee to owner
        super.transfer(owner(), gasFee);

        return true;
    }

    // Function to allow the HOLDING owner to "buy back" their HOLDING
    function buyBackHOLDING(string memory assetIpfsCID) external {
        // Ensure that the sender is the HOLDING owner
        HOLDING storage holding = holdings[msg.sender][assetIpfsCID];
        require(holding.owner == msg.sender, "Not the HOLDING owner");

        // Calculate the current value of the minerals in the HOLDING
        uint256 holdingValueInWei = calculateHOLDINGValueInWei(
            msg.sender,
            assetIpfsCID
        );

        // Ensure that the HOLDING value is greater than zero
        require(holdingValueInWei > 0, "HOLDING has no value");

        // Calculate the number of tokens to burn based on HOLDING value
        uint256 tokensToBurn = computeTokenToBurnByWei(holdingValueInWei);

        // Ensure that the HOLDING owner has enough tokens for the buyback
        require(
            balanceOf(msg.sender) >= tokensToBurn,
            "Insufficient tokens for buyback"
        );

        // Burn the tokens
        _burn(msg.sender, tokensToBurn);

        // Reset HOLDING details
        holding.owner = address(0);
        holding.assetIpfsCID = "";

        // Emit an event to log the HOLDING buyback
        emit HOLDINGBuyback(msg.sender, tokensToBurn, holdingValueInWei);
    }

    // Function to calculate the value of minerals in the HOLDING
    function calculateHOLDINGValueInWei(
        address holdingOwner,
        string memory assetIpfsCID
    ) public view returns (uint256) {
        HOLDING storage holding = holdings[holdingOwner][assetIpfsCID];
        require(holding.owner != address(0), "HOLDING not found");

        uint256 totalHOLDINGValue = 0;

        // Calculate the value of each mineral in the HOLDING
        for (uint256 i = 0; i < mineralSymbols.length; i++) {
            string memory mineralSymbol = mineralSymbols[i];
            Mineral storage mineral = holding.minerals[mineralSymbol];
            if (bytes(mineral.symbol).length > 0) {
                totalHOLDINGValue += calculateMineralValueInWei(
                    mineral.symbol,
                    mineral.ounces
                );
            }
        }

        return totalHOLDINGValue;
    }

    // Function to calculate the number of tokens to burn based on HOLDING value
    function computeTokenToBurnByWei(uint256 weiAmount)
    public
    view
    returns (uint256)
    {
        require(weiAmount > 0, "Value must > zero");

        uint256 price = getTokenValue();

        require(price > 0, "Token value must be > zero");

        // Calculate tokens to burn
        uint256 tokensToBurn = divide(weiAmount, price);

        return tokensToBurn;
    }

    // Function to update the gas fee percentage
    function setGasFeePercentage(uint256 _gasFeePercentage) external onlyOwner {
        gasFeePercentage = _gasFeePercentage;
    }

    function getTokenValue() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0; // Avoid division by zero if totalSupply is zero
        }
        return divide(totalAssetValue, totalSupply());
    }

    // Event to log HOLDING release
    event HOLDINGBuyback(
        address indexed sender,
        uint256 tokensToBurn,
        uint256 holdingValueInWei
    );

    // Event to log IPFS asset reference, mineral value, and mineral details
    event IPFSAssetReferenced(
        address indexed recipient,
        address indexed holdingOwner,
        string ipfsHash,
        uint256 mineralValue,
        uint256 tokenId
    );

    event MineralAdded(
        address indexed holdingOwner,
        string mineralSymbol,
        uint256 mineralOunces,
        uint256 mineralValue,
        uint256 tokensMinted,
        uint256 adminFee,
        uint256 amountTransferredToHOLDINGOwner
    );

    // Declare the event at the contract level
    event DebugLog(string message, uint256 value);
}