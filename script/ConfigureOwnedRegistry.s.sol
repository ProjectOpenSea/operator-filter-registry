// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OwnedRegistrant} from "../src/OwnedRegistrant.sol";
import {IOperatorFilterRegistry} from "../src/IOperatorFilterRegistry.sol";
import {DeployRegistry} from "./DeployRegistry.s.sol";
import {ScriptBase, console2} from "./ScriptBase.sol";

contract DeployRegistryAndConfigureOwnedRegistrant is ScriptBase {
    mapping(string => bool) selectedChains;

    function run() public {
        setUp();

        string[] memory chainNames = vm.envString("BROADCAST_CHAINS", ",");
        for (uint256 i = 0; i < chainNames.length; i++) {
            selectedChains[chainNames[i]] = true;
        }
        string[2][] memory rpcs = vm.rpcUrls();
        for (uint256 i = 0; i < rpcs.length; i++) {
            if (selectedChains[rpcs[i][0]]) {
                console2.log("Configuring registry on chain ", rpcs[i][0]);
                vm.createSelectFork(rpcs[i][1]);
                configure();
            }
        }
    }

    function configure() internal {
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(registryAddress);
        address[] memory addressesToAdd = vm.envAddress("NEW_FILTERED_ADDRESSES", ",");
        address[] memory addressesToRemove = vm.envAddress("REMOVE_FILTERED_ADDRESSES", ",");
        OwnedRegistrant registrant = OwnedRegistrant(vm.envAddress("REGISTRANT_ADDRESS"));

        vm.startBroadcast(deployer);
        if (addressesToAdd.length > 0) {
            registry.updateOperators(address(registrant), addressesToAdd, true);
        }
        if (addressesToRemove.length > 0) {
            registry.updateOperators(address(registrant), addressesToRemove, false);
        }
        vm.stopBroadcast();
    }
}
