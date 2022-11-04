// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry immutable operatorFilterRegistry;

    constructor(address registry, address subscriptionOrRegistantToCopy, bool subscribe) {
        operatorFilterRegistry = IOperatorFilterRegistry(registry);
        if (subscribe) {
            operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistantToCopy);
        } else {
            if (subscriptionOrRegistantToCopy != address(0)) {
                operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistantToCopy);
            } else {
                operatorFilterRegistry.register(address(this));
            }
        }
    }

    modifier onlyAllowedOperator(address addr) virtual {
        if (!operatorFilterRegistry.isOperatorAllowed(address(this), addr)) {
            revert OperatorNotAllowed(msg.sender);
        }
        _;
    }
}
