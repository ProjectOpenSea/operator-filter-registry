// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry immutable operatorFilterRegistry;

    constructor(address registry, address subscriptionOrRegistrantToCopy, bool subscribe) {
        operatorFilterRegistry = IOperatorFilterRegistry(registry);
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
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
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), addr)) {
                revert OperatorNotAllowed(addr);
            }
        }
        _;
    }
}
