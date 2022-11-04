// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnedRegistrant} from "../src/OwnedRegistrant.sol";
import {IOperatorFilterRegistry} from "../src/IOperatorFilterRegistry.sol";
import {ScriptBase} from "./ScriptBase.sol";

contract DeployRegistry is ScriptBase {
    function run() public {
        setUp();
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(registryAddress);
        address[] memory addressesToFilter = vm.envAddress("FILTERED_ADDRESSES", ",");
        vm.startBroadcast(deployer);
        OwnedRegistrant registrant = new OwnedRegistrant(registryAddress);
        vm.makePersistent(address(registrant));
        registry.updateOperators(address(registrant), addressesToFilter, true);
    }
}
