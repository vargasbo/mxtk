// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./mxtk.sol";
import "./priceEventEmitter.sol";

//Create different Price Oracles instances for all minerals supported
/// @custom:security-contact security@mineral-token.com
contract PriceOracle is AggregatorV3Interface, Ownable {

    string public name;
    string public symbol;
    MXTK public main;
    int256 internal _price;
    uint256 internal _version = 1;
    PriceEventEmitter public emitter;
    uint256 internal  _startedAt;
    uint256 internal _updatedAt;
    uint8 internal _decimals = 8;

    constructor(
        address initialOwner, // Address of the initial owner
        string memory _name,
        string memory _symbol,
        address _mxtk,
        address _priceEventEmitter,
        int256 initialPrice
    ) Ownable(initialOwner) {
        name = _name;
        symbol = _symbol;
        main = MXTK(_mxtk);
        main.updateMineralPriceOracle(_symbol, address(this), initialOwner);
        _price = initialPrice;
        emitter = PriceEventEmitter(_priceEventEmitter);
        _startedAt = block.timestamp;
        _updatedAt = block.timestamp;
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