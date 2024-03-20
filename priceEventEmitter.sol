// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact security@mineral-token.com
contract PriceEventEmitter is Ownable {

    constructor(address initialOwner) Ownable(initialOwner) {}

    event eventEmitted(string,int256);

    function emitEvent(string memory symbol,int256 price) public onlyOwner {
        emit eventEmitted(symbol, price);
    }
}