// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PalladiumPriceOracle is Ownable {
    uint256 public palladiumPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        palladiumPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the palladium price is updated
    event PalladiumPriceUpdated(uint256 newPrice);

    // Function to set the new palladium price
    function setPalladiumPrice(uint256 _newPrice) external onlyOwner {
        palladiumPrice = _newPrice;
        emit PalladiumPriceUpdated(_newPrice);
    }
}