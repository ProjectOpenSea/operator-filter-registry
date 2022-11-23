// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterRegistry} from "../src/OperatorFilterRegistry.sol";
import {Script, console2} from "forge-std/Script.sol";

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

contract ScriptBase is Script {
    address deployer;

    ImmutableCreate2Factory constant IMMUTABLE_CREATE2_FACTORY =
        ImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    function setUp() public {
        bytes32 pkey = vm.envBytes32("PRIVATE_KEY");
        deployer = vm.rememberKey(uint256(pkey));
    }
}
