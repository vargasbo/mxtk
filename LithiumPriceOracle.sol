// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LithiumPriceOracle is Ownable {
    uint256 public lithiumPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        lithiumPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the lithium price is updated
    event LithiumPriceUpdated(uint256 newPrice);

    // Function to set the new lithium price
    function setLithiumPrice(uint256 _newPrice) external onlyOwner {
        lithiumPrice = _newPrice;
        emit LithiumPriceUpdated(_newPrice);
    }
}