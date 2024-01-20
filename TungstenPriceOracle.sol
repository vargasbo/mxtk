// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TungstenPriceOracle is Ownable {
    uint256 public tungstenPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        tungstenPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the tungsten price is updated
    event TungstenPriceUpdated(uint256 newPrice);

    // Function to set the new tungsten price
    function setTungstenPrice(uint256 _newPrice) external onlyOwner {
        tungstenPrice = _newPrice;
        emit TungstenPriceUpdated(_newPrice);
    }
}