// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MaganesePriceOracle is Ownable {
    uint256 public maganesePrice;

    constructor(address initialOwner) Ownable(initialOwner){
        maganesePrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the maganese price is updated
    event MaganesePriceUpdated(uint256 newPrice);

    // Function to set the new maganese price
    function setMaganesePrice(uint256 _newPrice) external onlyOwner {
        maganesePrice = _newPrice;
        emit MaganesePriceUpdated(_newPrice);
    }
}