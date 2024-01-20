// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TanzanitePriceOracle is Ownable {
    uint256 public tanzanitePrice;

    constructor(address initialOwner) Ownable(initialOwner){
        tanzanitePrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the tanzanite price is updated
    event TanzanitePriceUpdated(uint256 newPrice);

    // Function to set the new tanzanite price
    function setTanzanitePrice(uint256 _newPrice) external onlyOwner {
        tanzanitePrice = _newPrice;
        emit TanzanitePriceUpdated(_newPrice);
    }
}