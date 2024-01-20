// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RhodiumPriceOracle is Ownable {
    uint256 public rhodiumPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        rhodiumPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the rhodium price is updated
    event RhodiumPriceUpdated(uint256 newPrice);

    // Function to set the new rhodium price
    function setRhodiumPrice(uint256 _newPrice) external onlyOwner {
        rhodiumPrice = _newPrice;
        emit RhodiumPriceUpdated(_newPrice);
    }
}