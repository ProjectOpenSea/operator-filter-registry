// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DefaultOperatorFilterer721} from "../../src/example/DefaultOperatorFilterer721.sol";

contract DefaultFilterer721 is DefaultOperatorFilterer721 {
    uint256 bal;

    constructor() DefaultOperatorFilterer721() {}

    function filterTest(address from) public onlyAllowedOperator(from) returns (bool) {
        return true;
    }

    function balanceOf(address) public view virtual override returns (uint256) {
        return bal;
    }

    function setBalance(uint256 amount) public {
        bal = amount;
    }
}
