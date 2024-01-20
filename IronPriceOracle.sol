// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract IronPriceOracle is Ownable {
    uint256 public ironPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        ironPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the iron price is updated
    event IronPriceUpdated(uint256 newPrice);

    // Function to set the new iron price
    function setIronPrice(uint256 _newPrice) external onlyOwner {
        ironPrice = _newPrice;
        emit IronPriceUpdated(_newPrice);
    }
}