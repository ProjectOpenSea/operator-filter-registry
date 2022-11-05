// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DefaultOperatorFilterer} from "../src/DefaultOperatorFilterer.sol";
import {OperatorFilterer} from "../src/OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {BaseRegistryTest} from "./BaseRegistryTest.sol";
import {OperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents} from "../src/OperatorFilterRegistry.sol";

contract DefaultFilterer is DefaultOperatorFilterer, Ownable {
    constructor() DefaultOperatorFilterer() {}

    function filterTest() public onlyAllowedOperator returns (bool) {
        return true;
    }
}

contract DefaultOperatorFiltererTest is BaseRegistryTest {
    DefaultFilterer filterer;
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function setUp() public override {
        super.setUp();

        vm.startPrank(DEFAULT_SUBSCRIPTION);
        registry.register(DEFAULT_SUBSCRIPTION);

        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), filteredAddress, true);
        filteredCodeHashAddress = makeAddr("filtered code hash");
        bytes memory code = hex"deadbeef";
        filteredCodeHash = keccak256(code);
        registry.updateCodeHash(address(DEFAULT_SUBSCRIPTION), filteredCodeHash, true);
        vm.etch(filteredCodeHashAddress, code);

        filterer = new DefaultFilterer();
        vm.stopPrank();
    }

    function testFilter() public {
        assertTrue(filterer.filterTest());
        vm.startPrank(filteredAddress);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        filterer.filterTest();
        vm.stopPrank();
        vm.startPrank(filteredCodeHashAddress);
        vm.expectRevert(abi.encodeWithSelector(CodeHashFiltered.selector, filteredCodeHashAddress, filteredCodeHash));
        filterer.filterTest();
    }
}
