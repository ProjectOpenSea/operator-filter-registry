// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry immutable operatorFilterRegistry;

    constructor(address registry, address subscriptionOrRegistrantToCopy, bool subscribe) {
        operatorFilterRegistry = IOperatorFilterRegistry(registry);
        if (registry.code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address addr) virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // to facilitate testing in environments without a filter registry
        if (address(registry).code.length > 0 && !registry.isOperatorAllowed(address(this), addr)) {
            revert OperatorNotAllowed(msg.sender);
        }
        _;
    }
}
