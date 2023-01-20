// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract OperatorFilterRegistryStub {
    function register(address) public pure {}

    function isOperatorAllowed(address, address) public pure returns (bool) {
        return false;
    }
}
