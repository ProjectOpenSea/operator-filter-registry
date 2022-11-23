// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OwnedRegistrant} from "../src/OwnedRegistrant.sol";
import {IOperatorFilterRegistry} from "../src/IOperatorFilterRegistry.sol";
import {DeployRegistry} from "./DeployRegistry.s.sol";
import {ScriptBase, console2} from "./ScriptBase.sol";

contract DeployRegistryAndConfigureOwnedRegistrant is ScriptBase {
    function run() public {
        setUp();
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(registryAddress);
        address[] memory addressesToFilter = vm.envAddress("FILTERED_ADDRESSES", ",");

        bytes memory creationCode = abi.encodePacked(type(OwnedRegistrant).creationCode, abi.encode(deployer));
        bytes32 salt = bytes32(uint256(uint160(deployer)) << 96);
        vm.startBroadcast(deployer);
        OwnedRegistrant registrant = OwnedRegistrant(IMMUTABLE_CREATE2_FACTORY.safeCreate2(salt, creationCode));
        registrant.acceptOwnership();
        registry.updateOperators(address(registrant), addressesToFilter, true);
    }
}
