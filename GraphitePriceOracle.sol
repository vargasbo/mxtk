// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GraphitePriceOracle is Ownable {
    uint256 public graphitePrice;

    constructor(address initialOwner) Ownable(initialOwner){
        graphitePrice = 10000000; // 10 cents, Price in 8 decimal
    }

    // Event to log when the graphite price is updated
    event GraphitePriceUpdated(uint256 newPrice);

    // Function to set the new graphite price
    function setGraphitePrice(uint256 _newPrice) external onlyOwner {
        graphitePrice = _newPrice; // Convert cents to wei (1e17 wei per cent)
        emit GraphitePriceUpdated(_newPrice);
    }
}