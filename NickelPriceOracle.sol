CobaltPriceOracle.sol// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NickelPriceOracle is Ownable {
    uint256 public nickelPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        nickelPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the nickel price is updated
    event NickelPriceUpdated(uint256 newPrice);

    // Function to set the new nickel price
    function setNickelPrice(uint256 _newPrice) external onlyOwner {
        nickelPrice = _newPrice;
        emit NickelPriceUpdated(_newPrice);
    }
}