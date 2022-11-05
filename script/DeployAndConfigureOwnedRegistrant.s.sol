// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnedRegistrant} from "../src/OwnedRegistrant.sol";
import {IOperatorFilterRegistry} from "../src/IOperatorFilterRegistry.sol";
import {ScriptBase} from "./ScriptBase.sol";
import {Test} from "forge-std/Test.sol";

interface ImmutableCreate2Factory {
    function findCreate2Address(bytes32 salt, bytes memory initCode)
        external
        view
        returns (address deploymentAddress);
    function findCreate2AddressViaHash(bytes32 salt, bytes32 initCodeHash)
        external
        view
        returns (address deploymentAddress);
    function hasBeenDeployed(address deploymentAddress) external view returns (bool);
    function safeCreate2(bytes32 salt, bytes memory initializationCode)
        external
        payable
        returns (address deploymentAddress);
}

contract DeployRegistryAndConfigureOwnedRegistrant is ScriptBase, Test {
    ImmutableCreate2Factory constant CREATE2_FACTORY =
        ImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    function run() public {
        setUp();
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(registryAddress);
        address[] memory addressesToFilter = vm.envAddress("FILTERED_ADDRESSES", ",");

        bytes memory creationCode =
            abi.encodePacked(type(OwnedRegistrant).creationCode, abi.encode(registryAddress, deployer));
        bytes32 salt = bytes32(uint256(uint160(deployer)) << 96);
        emit log_named_bytes32("salt", salt);
        vm.startBroadcast(deployer);
        OwnedRegistrant registrant = OwnedRegistrant(CREATE2_FACTORY.safeCreate2(salt, creationCode));
        registrant.acceptOwnership();
        registry.updateOperators(address(registrant), addressesToFilter, true);
    }
}
