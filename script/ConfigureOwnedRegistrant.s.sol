// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OwnedRegistrant} from "../src/OwnedRegistrant.sol";
import {IOperatorFilterRegistry} from "../src/IOperatorFilterRegistry.sol";
import {DeployRegistry} from "./DeployRegistry.s.sol";
import {ScriptBase, console2} from "./ScriptBase.sol";

contract ConfigureOwnedRegistrant is ScriptBase {
    function run() public {
        setUp();
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(registryAddress);
        OwnedRegistrant registrant = OwnedRegistrant(vm.envAddress("REGISTRANT_ADDRESS"));
        address[] memory add = vm.envAddress("NEW_FILTERED_ADDRESSES", ",");
        address[] memory remove = vm.envAddress("REMOVE_FILTERED_ADDRESSES", ",");

        string[] memory chains = vm.envString("CHAINS", ",");
        for (uint256 i = 0; i < chains.length; i++) {
            string memory chain = chains[i];
            vm.createSelectFork(stdChains[chain].rpcUrl);
            vm.startBroadcast(deployer);
            registry.updateOperators(address(registrant), add, true);
            registry.updateOperators(address(registrant), remove, false);
            vm.stopBroadcast();
        }
    }
}
