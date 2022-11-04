// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OperatorFilterRegistry} from "../src/OperatorFilterRegistry.sol";
import {ScriptBase} from "./ScriptBase.sol";

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

contract DeployRegistry is ScriptBase {
    ImmutableCreate2Factory constant CREATE2_FACTORY =
        ImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    function run() public {
        setUp();
        bytes memory creationCode = type(OperatorFilterRegistry).creationCode;
        bytes32 salt = bytes32(0);

        vm.broadcast(deployer);
        CREATE2_FACTORY.safeCreate2(salt, creationCode);
    }
}
