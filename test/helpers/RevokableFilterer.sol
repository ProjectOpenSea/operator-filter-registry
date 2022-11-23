// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableOperatorFilterer} from "../../src/RevokableOperatorFilterer.sol";
import {UpdatableOperatorFilterer} from "../../src/UpdatableOperatorFilterer.sol";

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract RevokableFilterer is RevokableOperatorFilterer, Ownable {
    constructor(address registry) RevokableOperatorFilterer(registry, address(0), false) {}

    function testFilter(address from) public view onlyAllowedOperator(from) returns (bool) {
        return true;
    }

    function owner() public view override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
}
