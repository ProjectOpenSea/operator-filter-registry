// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OperatorFilterRegistry} from "../src/OperatorFilterRegistry.sol";
import {ScriptBase} from "./ScriptBase.sol";

contract DeployRegistry is ScriptBase {
    function run() public {
        setUp();
        vm.startBroadcast(deployer);
        OperatorFilterRegistry registry = new OperatorFilterRegistry();
        vm.makePersistent(address(registry));
    }
}
