// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OperatorFilterRegistry} from "../src/OperatorFilterRegistry.sol";
import {Script} from "forge-std/Script.sol";

contract ScriptBase is Script {
    address deployer;

    function setUp() public {
        bytes32 pkey = vm.envBytes32("PRIVATE_KEY");
        deployer = vm.rememberKey(uint256(pkey));
    }
}
