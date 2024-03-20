// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact security@mineral-token.com
contract PriceEventEmitter is Ownable {

    constructor(address initialOwner) Ownable(initialOwner) {}

    event eventEmitted(string,int256);

    function emitEvent(string memory symbol,int256 price, address ownerAddress) public{
        require(ownerAddress == owner(), "Only the contract owner can emit the mineral price oracle");
        emit eventEmitted(symbol, price);
    }
}