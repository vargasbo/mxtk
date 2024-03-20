// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/// @custom:security-contact security@mineral-token.com
contract PriceEventEmitter {
    constructor(){
    }
    event eventEmitted(string,int256);

    function emitEvent(string memory symbol,int256 price) public {
        emit eventEmitted(symbol, price);
    }
}