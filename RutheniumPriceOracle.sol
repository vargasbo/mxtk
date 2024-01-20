// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RutheniumPriceOracle is Ownable {
    uint256 public rutheniumPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        rutheniumPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the ruthenium price is updated
    event RutheniumPriceUpdated(uint256 newPrice);

    // Function to set the new ruthenium price
    function setRutheniumPrice(uint256 _newPrice) external onlyOwner {
        rutheniumPrice = _newPrice;
        emit RutheniumPriceUpdated(_newPrice);
    }
}