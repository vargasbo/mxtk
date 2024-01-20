// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CobaltPriceOracle is Ownable {
    uint256 public cobaltPrice;

    constructor(address initialOwner) Ownable(initialOwner){
        cobaltPrice = 24000000; //24 cents; 8 decimal position
    }

    // Event to log when the copper price is updated
    event CobaltPriceUpdated(uint256 newPrice);

    // Function to set the new copper price
    function setCobaltPrice(uint256 _newPrice) external onlyOwner {
        cobaltPrice = _newPrice;
        emit CobaltPriceUpdated(_newPrice);
    }
}