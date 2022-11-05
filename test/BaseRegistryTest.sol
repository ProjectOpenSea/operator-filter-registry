// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents} from "../src/OperatorFilterRegistry.sol";

contract BaseRegistryTest is Test, OperatorFilterRegistryErrorsAndEvents {
    OperatorFilterRegistry constant registry = OperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    function setUp() public virtual {
        address deployedRegistry = address(new OperatorFilterRegistry());
        vm.etch(address(registry), deployedRegistry.code);
    }
}
