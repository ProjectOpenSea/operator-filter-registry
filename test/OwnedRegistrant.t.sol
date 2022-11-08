// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OwnedRegistrant} from "../src/OwnedRegistrant.sol";
import {BaseRegistryTest} from "./BaseRegistryTest.sol";

contract OperatorFiltererTest is BaseRegistryTest {
    OwnedRegistrant registrant;
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;

    function setUp() public override {
        super.setUp();

        registrant = new OwnedRegistrant(address(this));
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
