// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OsmiumPriceOracle is Ownable {
    uint256 public osmiumPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        osmiumPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the osmium price is updated
    event OsmiumPriceUpdated(uint256 newPrice);

    // Function to set the new osmium price
    function setOsmiumPrice(uint256 _newPrice) external onlyOwner {
        osmiumPrice = _newPrice;
        emit OsmiumPriceUpdated(_newPrice);
    }
}