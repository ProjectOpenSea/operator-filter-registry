// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DefaultOperatorFilterer721} from "../../src/example/DefaultOperatorFilterer721.sol";

contract DefaultFilterer721 is DefaultOperatorFilterer721 {
    constructor() DefaultOperatorFilterer721() {}

    function filterTest(address from) public onlyAllowedOperator(from) returns (bool) {
        return true;
    }
}
