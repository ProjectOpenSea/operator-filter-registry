// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterRegistry} from "../src/OperatorFilterRegistry.sol";
import {ScriptBase, console2} from "./ScriptBase.sol";

contract DeployRegistry is ScriptBase {
    function run() public {
        setUp();
        bytes memory creationCode = type(OperatorFilterRegistry).creationCode;
        console2.logBytes32(keccak256(creationCode));
        bytes32 salt = bytes32(0x0000000000000000000000000000000000000000d40ba0de8b5adb1cc4070000);
        // bytes32 salt = bytes32(0);

        vm.broadcast(deployer);
        IMMUTABLE_CREATE2_FACTORY.safeCreate2(salt, creationCode);
    }
}
