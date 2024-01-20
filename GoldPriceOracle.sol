// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GoldPriceOracle is Ownable {
    uint256 public goldPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        goldPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the gold price is updated
    event GoldPriceUpdated(uint256 newPrice);

    // Function to set the new gold price
    function setGoldPrice(uint256 _newPrice) external onlyOwner {
        goldPrice = _newPrice;
        emit GoldPriceUpdated(_newPrice);
    }
}