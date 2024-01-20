// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ChromiumPriceOracle is Ownable {
    uint256 public chromiumPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        chromiumPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the price is updated
    event ChromiumPriceUpdated(uint256 newPrice);

    // Function to set the new copper price
    function setCopperPrice(uint256 _newPrice) external onlyOwner {
        copperPrice = _newPrice;
        emit ChromiumPriceUpdated(_newPrice);
    }
}