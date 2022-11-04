// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OperatorFilterer} from "./OperatorFilterer.sol";

contract DefaultOperatorFilterer is OperatorFilterer {
    // todo: update with correct addresses
    address constant DEFAULT_OPERATOR_FILTER_REGISTRY = address(0xdeadbeef);
    address constant DEFAULT_SUBSCRIPTION = address(0xdadb0d);

    constructor() OperatorFilterer(DEFAULT_OPERATOR_FILTER_REGISTRY, DEFAULT_SUBSCRIPTION, true) {}
}
