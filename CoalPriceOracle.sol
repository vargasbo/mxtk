// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CoalPriceOracle is Ownable {
    uint256 public coalPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        coalPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the coal price is updated
    event CoalPriceUpdated(uint256 newPrice);

    // Function to set the new coal price
    function setCoalPrice(uint256 _newPrice) external onlyOwner {
        coalPrice = _newPrice;
        emit CoalPriceUpdated(_newPrice);
    }
}