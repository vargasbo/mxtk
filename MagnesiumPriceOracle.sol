// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MagnesiumPriceOracle is Ownable {
    uint256 public magnesiumPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        magnesiumPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the magnesium price is updated
    event MagnesiumPriceUpdated(uint256 newPrice);

    // Function to set the new magnesium price
    function setMagnesiumPrice(uint256 _newPrice) external onlyOwner {
        magnesiumPrice = _newPrice;
        emit MagnesiumPriceUpdated(_newPrice);
    }
}