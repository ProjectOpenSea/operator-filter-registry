// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DefaultOperatorFilterer} from "../../src/DefaultOperatorFilterer.sol";

contract DefaultFilterer is DefaultOperatorFilterer {
    constructor() DefaultOperatorFilterer() {}

    function filterTest(address from) public view onlyAllowedOperator(from) returns (bool) {
        return true;
    }
}
