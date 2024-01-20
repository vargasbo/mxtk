// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SilverPriceOracle is Ownable {
    uint256 public silverPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        silverPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the silver price is updated
    event SilverPriceUpdated(uint256 newPrice);

    // Function to set the new silver price
    function setSilverPrice(uint256 _newPrice) external onlyOwner {
        silverPrice = _newPrice;
        emit SilverPriceUpdated(_newPrice);
    }
}