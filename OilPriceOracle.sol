// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OilPriceOracle is Ownable {
    uint256 public oilPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        oilPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the oil price is updated
    event OilPriceUpdated(uint256 newPrice);

    // Function to set the new oil price
    function setOilPrice(uint256 _newPrice) external onlyOwner {
        oilPrice = _newPrice;
        emit OilPriceUpdated(_newPrice);
    }
}