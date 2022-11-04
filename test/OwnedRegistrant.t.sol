// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnedRegistrant} from "../src/OwnedRegistrant.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {OperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents} from "../src/OperatorFilterRegistry.sol";

contract OperatorFiltererTest is Test, OperatorFilterRegistryErrorsAndEvents {
    OwnedRegistrant registrant;
    OperatorFilterRegistry registry;
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;

    function setUp() public {
        registry = new OperatorFilterRegistry();

        registrant = new OwnedRegistrant(address(registry));
        filteredAddress = makeAddr("filtered address");
        filteredCodeHashAddress = makeAddr("filtered code hash");
        bytes memory code = hex"deadbeef";
        filteredCodeHash = keccak256(code);
    }

    function testConstructor() public {
        assertTrue(registry.isRegistered(address(registrant)));
        registry.updateOperator(address(registrant), filteredAddress, true);
        assertTrue(registry.isOperatorFiltered(address(registrant), filteredAddress));
    }
}
