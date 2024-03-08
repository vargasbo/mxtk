// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

contract MXTK is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable,
OwnableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

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

    mapping(string=>uint) internal MineralPrices;
    mapping(string=>address) internal MineralPricesOracle;

    function initialize() initializer public {
        __ERC20_init("Mineral Token", "MXTK");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(msg.sender);
        __ERC20Permit_init("Mineral Token");
        __UUPSUpgradeable_init();

        gasFeePercentage = 70; // Default to 70 bps (0.7%)
        auPriceFeed = AggregatorV3Interface(
        //0x7b219F57a8e9C7303204Af681e9fA69d17ef626f //testnet
            0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6  //mainNet
        ); //XAU/USD address

        // Initialize mineralSymbols with default symbols
        mineralSymbols.push("CU");
        MineralPricesOracle["CU"] = address(0);
        MineralPrices["CU"] = 10000; //default value for copper over from existing holdings

        mineralSymbols.push("AU");
        MineralPrices["AU"] = 10000;  //this is the only one using from chainLink

        mineralSymbols.push("GR");
        MineralPricesOracle["GR"] = address(0);
        MineralPrices["GR"] = 10000;  //default value since porting over existing Holdings

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

        totalAssetValue = 0;

        setInitialValues();

    }



    // Gas fee percentage
    uint256 public gasFeePercentage;

    mapping(address=>mapping(string=>mapping(string=>uint))) public newHoldings;

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


    event MineralPriceUpdated(string,uint);

    function updateGoldPriceOracle(address goldOracleAddress)
    external
    onlyOwner
    {
        require(goldOracleAddress != address(0), "Invalid address");
        auPriceFeed = AggregatorV3Interface(goldOracleAddress);
    }


    function updateMineralPriceOracle(string memory mineralSymbol,address priceOracleAddress, address msgSender) public {
        require(msgSender == owner(), "Only the contract owner can update the mineral price oracle");
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
        require(bytes(assetIpfsCID).length > 0, "CID cannot be empty");
        require(mineralOunces > 0, "Oz must be greater than zero");
        require(bytes(mineralSymbol).length > 0, "Symbol cannot be empty");

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
    }

    function addMineralToHolding(
        address holdingOwner,
        string memory assetIpfsCID,
        string memory mineralSymbol,
        uint256 mineralOunces
    ) external onlyOwner {
        require(holdingOwner != address(0), "Holding not found");
        require(bytes(assetIpfsCID).length > 0, "CID cannot be empty");
        require(mineralOunces > 0, "Oz must be greater than zero");
        require(bytes(mineralSymbol).length > 0, "Symbol cannot be empty");

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

        // Calculate tokens to mint
        uint256 tokensToMintInWei = computeTokenToMintByWei(mineralValueInWei);

        // Calculate admin fee
        uint256 adminFeeInWei = calculateAdminFee(tokensToMintInWei);

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

    event TokenPriceUpdated(uint);

    // Function to update prices of underlying assets and compute token price
    function updateAndComputeTokenPrice() public {
        // Update the prices of underlying assets
        // Recalculate the total asset value and token price
        totalAssetValue = calculateTotalAssetValue();
        uint256 newTokenPrice = computeTokenPrice();

        // Emit an event or log the updated token price
        emit TokenPriceUpdated(newTokenPrice);
    }

    // Function to calculate the total value of all assets in the contract
    function calculateTotalAssetValue() internal view returns (uint256) {
        uint256 totalValue = 0;

        for(uint256 i = 0 ; i < newHoldingArray.length;i++){
            totalValue+=  calculateMineralValueInWei(newHoldingArray[i].mineralSymbol, newHoldingArray[i].ounces);
        }

        return totalValue;
    }

    // Function to compute the new token price based on total asset value
    function computeTokenPrice() internal view returns (uint256) {
        // Ensure that totalSupply() is greater than zero to avoid division by zero
        require(totalSupply() > 0, "Total supply must be greater than zero");

        // Calculate the new token price based on total asset value and total supply
        return (totalAssetValue / 1e18) / (totalSupply() / 1e18);
    }

    function _addMineralSymbol(string memory mineralSymbol) internal {

        // to keep a list of these synthetic elements not on table. You might come up with a better solution.
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


    // Function to add a mineral symbol to the array
    function addMineralSymbol(string memory mineralSymbol) external onlyOwner{
        _addMineralSymbol(mineralSymbol);
    }


    function computeTokenToMintByWei(uint256 weiAmount)
    public
    pure
    returns (uint256)
    {
        require(weiAmount > 0, "Value must > zero");

        uint256 baseDeno = baseValue();

        // Calculate token to mint
        uint256 tokensToMintInWei = divide(weiAmount, baseDeno);

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
        return (tokensToMintInWei * 40) / 100;
    }

    // Function to calculate the value of a mineral based on its symbol and ounces
    function calculateMineralValueInWei(
        string memory mineralSymbol,
        uint256 mineralOunces
    ) public view returns (uint256) {
        uint256 mineralPrice = getMineralPrice(mineralSymbol);
        return mineralPrice * mineralOunces * 10**10;
    }

    function getMineralPrice(string memory mineralSymbol) public view returns (uint256) {
        //Gold is using the existing Price Oracle; call that vs internal
        if (keccak256(bytes(mineralSymbol)) == keccak256(bytes("AU"))) {
            return uint256(getGoldPrice());
        } else{
            int256 price = 0;
            AggregatorV3Interface tx1 = AggregatorV3Interface(MineralPricesOracle[mineralSymbol]);
            (, price, , , ) = tx1.latestRoundData();

            return uint256(price);
        }
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

    // Function to allow the Holding owner to "buy back" their Holding
    function buyBackHolding(address holdingOwner,string memory ipfsCID) external onlyOwner{
        // Calculate the current value of the minerals in the Holding
        uint256 holdingValueInWei = calculateHoldingValueInWei(
            holdingOwner, ipfsCID
        );

        // Ensure that the Holding value is greater than zero
        require(holdingValueInWei > 0, "Holding has no value");

        // Calculate the number of tokens to burn based on Holding value
        uint256 tokensToBurn = computeTokenToBurnByWei(holdingValueInWei);

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
        for (uint256 i = 0; i < newHoldingArray.length; i++) {
            if (newHoldingArray[i].owner == holdingOwner&&
                keccak256(bytes(newHoldingArray[i].assetIpfsCID)) == keccak256(bytes(ipfsCid))
            ) {
                // Remove the holding by swapping with the last element and then reducing the array length
                newHoldingArray[i] = newHoldingArray[newHoldingArray.length - 1];
                delete newHoldingArray[newHoldingArray.length - 1];
                newHoldingArray.pop();
                break;
            }
        }
    }

    // Function to calculate the value of minerals in the Holding
    function calculateHoldingValueInWei(
        address holdingOwner,
        string memory ipfsCid
    ) public view returns (uint256) {

        uint256 totalHoldingValue = 0;

        // Calculate the value of each mineral in the Holding
        for (uint256 i = 0; i < newHoldingArray.length; i++) {
            if (newHoldingArray[i].owner==holdingOwner &&
                keccak256(bytes(newHoldingArray[i].assetIpfsCID)) == keccak256(bytes(ipfsCid))
            ) {

                totalHoldingValue += calculateMineralValueInWei(
                    newHoldingArray[i].mineralSymbol,
                    newHoldingArray[i].ounces
                );
            }
        }

        return totalHoldingValue;
    }

    // Function to calculate the number of tokens to burn based on Holding value
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
        return (totalAssetValue / 1e18) / (totalSupply() / 1e18);
    }

    // Event to log Holding release
    event HoldingBuyback(
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
        uint256 amountTransferredToHoldingOwner
    );

    // Declare the event at the contract level
    event DebugLog(string message, uint256 value);

    bool internal calledOnce;

    function baseValue() public pure returns (uint256) {
        return 159089461098;
    }

    function setInitialValues() internal {
        require(!calledOnce,"already called");

        _mint(0x91852aEC928690F4F55e556c4b000302b04c3e30,4601442839954048884548696); //1
        _mint(0xb36C15f1ED5cedb9E913218219016d8Cf5Ac864F,4255602869571497331219493); //2
        _mint(0x121B039CBc60aA1bf563306eB24013D0e1bA0989,2672762772000000000000000); //3
        _mint(0xB3f46cC55a50225f197AE5a4d1545350f48B2F0b,624477244200000000000000);  //4

        _mint(0xf49a4C1A5250aF8Da4beB67b9C28e82f7D1E8D92,198600000000000000000); //5
        _mint(0xc2DE3C2143a0c979Ee00019BeDEfF89AE8124262,198600000000000000000); //6
        _mint(0x4bD9Ea8D612aD197de3d3180db0A60bC7Cbc3189,198600000000000000000); //7
        _mint(0xB9aD5fd45F3A36Be70E2fD2F661060ddc1D0fc09,198600000000000000000); //8
        _mint(0xd79497C683BD0eA45DaFc8b732cBf7344F5Df231,3152775000000000000); //9
        _mint(0xE1a0508BB886C110f2238C0232795c30d99C71D7,93448174827476894);  //10
        _mint(0xDf0a2F8E8c5a78D1E501382060C803750C5E5821,30783000000000000);  //11
        _mint(0x5c5Eac6cE39623A023F886eC015C635b04a95f71,13902000000000000);  //12
        _mint(0xd0684c3311483027bAaFCDd3dB91876BEd5b86c9,4956360431002742);  //13

        calledOnce = true;
    }

    //To be called after the proxy has been deployed
    function portExistingMinerals() external onlyOwner{
        // Add initial minerals using the addMineralToHolding function
        existingDataToHolding(0x91852aEC928690F4F55e556c4b000302b04c3e30, "Qmb4am5G3yZKfQd3nBtuhWHmXTgzr6y6cV8dFwp3f9WTGn", "GR", 192000000000);
        existingDataToHolding(0x91852aEC928690F4F55e556c4b000302b04c3e30, "QmRohsANeKkPktGDmfWdpKuBmcCizEJS2TnXV6m1tBdYAQ", "AU", 71651);
    }

}

//Used to publish event changes from Price Oracle
contract PriceEventEmitter {
    constructor(){
    }
    event eventEmitted(string,int);

    function emitEvent(string memory symbol,int price) public {
        emit eventEmitted(symbol, price);
    }
}

//Create different Price Oracles instances for all minerals supported
contract PriceOracle is AggregatorV3Interface, Ownable {

    string public name;
    string public symbol;
    address public admin;
    MXTK public main;
    int internal _price;
    uint internal _version = 1;
    PriceEventEmitter public emitter;
    uint internal  _startedAt;
    uint internal _updatedAt;
    uint8 internal _decimals = 8;

    constructor(
        address initialOwner, // Address of the initial owner
        string memory _name,
        string memory _symbol,
        address _mxtk,
        address _priceEventEmitter,
        int initialPrice
    ) Ownable(initialOwner) {
        name = _name;
        symbol = _symbol;
        admin = initialOwner; // Set initial admin to the contract deployer
        main = MXTK(_mxtk);
        main.updateMineralPriceOracle(_symbol, address(this), initialOwner);
        _price = initialPrice;
        emitter = PriceEventEmitter(_priceEventEmitter);
        _startedAt = block.timestamp;
        _updatedAt = block.timestamp;
    }

    modifier onlyAdmin{
        require(msg.sender==admin,"you are not admin");
        _;
    }

    function changeAdmin(address newAdmin) public onlyAdmin{
        admin = newAdmin;
    }

    function decimals()
    external
    view
    returns (
        uint8
    ){return _decimals;}

    function description()
    external
    view
    returns (
        string memory
    ){return name;}

    function version()
    external
    view
    returns (
        uint256
    ){return _version;}

    function getRoundData(
        uint80 _roundId
    )
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ){roundId = _roundId;
        answer = _price;
        startedAt = 0;
        updatedAt = block.timestamp;
        answeredInRound = _roundId;
    }

    function changePrice(int newPrice) public onlyOwner {
        _price = newPrice;
        main.updateAndComputeTokenPrice();
        _updatedAt = block.timestamp;
        emitter.emitEvent(symbol, newPrice);
    }

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ){
        roundId =0;
        answer = _price;
        startedAt =_startedAt;
        updatedAt = _updatedAt;
        answeredInRound = 0;

    }

}