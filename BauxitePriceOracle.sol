// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BauxitePriceOracle is Ownable {
    uint256 public bauxitePrice;

    constructor(address initialOwner) Ownable(initialOwner){
        bauxitePrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the Bauxite price is updated
    event BauxitePriceUpdated(uint256 newPrice);

    // Function to set the new Bauxite price
    function setBauxitePrice(uint256 _newPrice) external onlyOwner {
        bauxitePrice = _newPrice;
        emit BauxitePriceUpdated(_newPrice);
    }
}