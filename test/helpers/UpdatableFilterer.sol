// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UpdatableOperatorFilterer} from "../../src/UpdatableOperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract UpdatableFilterer is UpdatableOperatorFilterer, Ownable {
    constructor(address registry) UpdatableOperatorFilterer(registry, address(0), false) {}

    function testFilter(address from) public view onlyAllowedOperator(from) returns (bool) {
        return true;
    }

    function owner() public view override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
}
