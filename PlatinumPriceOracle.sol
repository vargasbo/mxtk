// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PlatinumPriceOracle is Ownable {
    uint256 public platinumPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        platinumPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the platinum price is updated
    event PlatinumPriceUpdated(uint256 newPrice);

    // Function to set the new platinum price
    function setPlatinumPrice(uint256 _newPrice) external onlyOwner {
        platinumPrice = _newPrice;
        emit PlatinumPriceUpdated(_newPrice);
    }
}