// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CopperPriceOracle is Ownable {
    uint256 public copperPrice;

    constructor() {
        copperPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the copper price is updated
    event CopperPriceUpdated(uint256 newPrice);

    // Function to set the new copper price
    function setCopperPrice(uint256 _newPrice) external onlyOwner {
        copperPrice = _newPrice;
        emit CopperPriceUpdated(_newPrice);
    }
}