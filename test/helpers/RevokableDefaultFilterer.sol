// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableDefaultOperatorFilterer} from "../../src/RevokableDefaultOperatorFilterer.sol";

contract RevokableDefaultFilterer is RevokableDefaultOperatorFilterer {
    address _owner;

    constructor() RevokableDefaultOperatorFilterer() {
        _owner = msg.sender;
    }

    function filterTest(address from) public view onlyAllowedOperator(from) returns (bool) {
        return true;
    }

    function owner() public view override returns (address) {
        return _owner;
    }
}
