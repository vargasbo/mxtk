// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

//Used to publish event changes from Price Oracle
contract PriceEventEmitter {
    constructor(){
    }
    event eventEmitted(string,int);

    function emitEvent(string memory symbol,int price) public {
        emit eventEmitted(symbol, price);
    }
}