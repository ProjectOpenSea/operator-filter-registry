// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {Ownable2Step} from "openzeppelin-contracts/access/Ownable2Step.sol";

/**
 * @title  OwnedRegistrant
 * @notice Ownable contract that registers itself with the OperatorFilterRegistry and administers its own entries,
 *         to facilitate a subscription whose ownership can be transferred.
 */
contract OwnedRegistrant is Ownable2Step {
    IOperatorFilterRegistry immutable registry;

    constructor(address _registry, address _owner) {
        registry = IOperatorFilterRegistry(_registry);
        registry.register(address(this));
        transferOwnership(_owner);
    }
}
