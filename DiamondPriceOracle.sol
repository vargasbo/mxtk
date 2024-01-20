// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DiamondPriceOracle is Ownable {
    uint256 public diamondPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        diamondPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the diamond price is updated
    event DiamondPriceUpdated(uint256 newPrice);

    // Function to set the new diamond price
    function setDiamondPrice(uint256 _newPrice) external onlyOwner {
        diamondPrice = _newPrice;
        emit DiamondPriceUpdated(_newPrice);
    }
}