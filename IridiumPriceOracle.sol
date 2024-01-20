// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract IridiumPriceOracle is Ownable {
    uint256 public iridiumPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        iridiumPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the iridium price is updated
    event IridiumPriceUpdated(uint256 newPrice);

    // Function to set the new iridium price
    function setIridiumPrice(uint256 _newPrice) external onlyOwner {
        iridiumPrice = _newPrice;
        emit IridiumPriceUpdated(_newPrice);
    }
}