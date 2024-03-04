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


contract eventEmitter {
    constructor(){

    }

    event eventEmitted(string,int);

    function emitEvent(string memory _str,int _int) public {
        emit eventEmitted(_str,_int);
    }


}


contract PriceOracle is AggregatorV3Interface {
  
  string public name;
  string public symbol;
  address public admin;
  MXTK public main;
  int public Answer;
  eventEmitter public emitter;

  constructor(string memory _name,string memory _symbol,address _MXTK,address _eventEmitter,int initialPrice){
    name = _name;
    symbol = _symbol;
    admin = msg.sender;
    main =MXTK(_MXTK);
    main.updateMineralPriceOracle(_symbol, address(this));
    Answer = initialPrice;
    emitter = eventEmitter(_eventEmitter);
  }

  modifier onlyAdmin{
    require(msg.sender==admin,"you are not admin");
    _;
  }

  function chandAdmin(address _new) public onlyAdmin{
    admin = _new;
  }

  function decimals()
    external
    view
    returns (
      uint8
    ){}

  function description()
    external
    view
    returns (
      string memory
    ){}

  function version()
    external
    view
    returns (
      uint256
    ){}

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
    ){}



    function changeAnswer(int _num) public onlyAdmin {
        Answer = _num;
        main.updateAndComputeTokenPrice();
        emitter.emitEvent(symbol,_num);
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
        answer = Answer;
        startedAt =0;
        updatedAt = 0;
        answeredInRound = 0;

    }


}











contract MXTK is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable,
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

//    using EnumerableMap for EnumerableMap.AddressToUintMap;
    mapping(string=>uint) public MineralPrices;
    mapping(string=>address) public MineralPricesOracle;
    uint256 internal initAssetValue;

    function initialize() initializer public {
        __ERC20_init("Mineral Token", "MXTK");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(msg.sender);
        __ERC20Permit_init("Mineral Token");
        __UUPSUpgradeable_init();

        gasFeePercentage = 70; // Default to 70 bps (0.7%)
        ethPriceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
            //0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); //ETH/USD address
        auPriceFeed = AggregatorV3Interface(
            0x7b219F57a8e9C7303204Af681e9fA69d17ef626f
            //0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6
        ); //XAU/USD address

        // Initialize mineralSymbols with default symbols
        mineralSymbols.push("CU");
        MineralPricesOracle["CU"] = address(0);
        mineralSymbols.push("AU");
        MineralPrices["AU"] = 0;   //this is the only one using from chainlink
        mineralSymbols.push("GR");
        MineralPricesOracle["GR"] = address(0);
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

        setInitialValues();

    }



    // Gas fee percentage
    uint256 public gasFeePercentage;

    mapping(address=>mapping(string=>mapping(string=>uint))) public newHoldings;
    
    struct newHOLDINGs {
        address owner;
        string assetIpfsCID;
        string mineralSymbol;
        uint256 ounces;
    
    }
    
    newHOLDINGs[] public newHOLDINGArray;
    uint256 public newHOLDINGsIndex;
    
    

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

    function updateMineralPriceOracle(string memory _min,address priceOracleAddress)
    public
    
    {

        MineralPricesOracle[_min]=priceOracleAddress;
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



        // Check if the mineral already exists for this HOLDING
        require(
            newHoldings[holdingOwner][assetIpfsCID][mineralSymbol]==0,
            "Mineral already exists"
        );

  
        newHoldings[holdingOwner][assetIpfsCID][mineralSymbol]=mineralOunces;

        newHOLDINGs memory tx1 = newHOLDINGs(holdingOwner,assetIpfsCID,mineralSymbol,mineralOunces);
        newHOLDINGArray.push(tx1);
        newHOLDINGsIndex++;


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

        updateAndComputeTokenPrice();
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

    event TokenPriceUpdated(uint);

    // Function to update prices of underlying assets and compute token price
    function updateAndComputeTokenPrice(
        // uint256 newGraphitePrice,
        // uint256 newCopperPrice
    ) public {
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

        //TODO: This needs to be refactor for performance/cost



        for(uint256 i = 0 ; i < newHOLDINGArray.length;i++){
              totalValue+=  calculateMineralValueInWei(newHOLDINGArray[i].mineralSymbol,newHOLDINGArray[i].ounces); 
        }



        return totalValue+ initAssetValue;
    }

    // Function to compute the new token price based on total asset value
    function computeTokenPrice() internal view returns (uint256) {
        // Ensure that totalSupply() is greater than zero to avoid division by zero
        require(totalSupply() > 0, "Total supply must be greater than zero");

        // Calculate the new token price based on total asset value and total supply
        return totalAssetValue / totalSupply();
    }

    // Function to add a mineral symbol to the array
    function addMineralSymbol(string memory mineralSymbol) public {

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

    function computeTokenToMintByWei(uint256 weiAmount)
    public
    view
    returns (uint256)
    {
        require(weiAmount > 0, "Value must > zero");



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


        return uint(getMineralPrice(mineralSymbol)) * mineralOunces;
    }

    function getMineralPrice(string memory _min) public view returns (int256) {
        
        
        AggregatorV3Interface tx1 = AggregatorV3Interface(MineralPricesOracle[_min]); 
        (, int256 price, , , ) = tx1.latestRoundData();
        return price;
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
    function buyBackHOLDING(
        //string memory assetIpfsCID
        ) external {
        // Ensure that the sender is the HOLDING owner

        // Calculate the current value of the minerals in the HOLDING
        uint256 holdingValueInWei = calculateHOLDINGValueInWei(
            msg.sender

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

 

        // Emit an event to log the HOLDING buyback
        emit HoldingBuyback(msg.sender, tokensToBurn, holdingValueInWei);
    }

    // Function to calculate the value of minerals in the HOLDING
    function calculateHOLDINGValueInWei(
        address holdingOwner
 
    ) public view returns (uint256) {

        uint256 totalHOLDINGValue = 0;

        // Calculate the value of each mineral in the HOLDING
        for (uint256 i = 0; i < newHOLDINGArray.length; i++) {
            if (newHOLDINGArray[i].owner==holdingOwner) {
                totalHOLDINGValue += calculateMineralValueInWei(
                    newHOLDINGArray[i].mineralSymbol,
                    newHOLDINGArray[i].ounces
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
        uint256 amountTransferredToHOLDINGOwner
    );

   

    // Declare the event at the contract level
    event DebugLog(string message, uint256 value);

        bool public calledOnce;

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

        initAssetValue = 1933745671142000000;
        totalAssetValue = 1933745671142000000;
        

        calledOnce = true;
    }
}