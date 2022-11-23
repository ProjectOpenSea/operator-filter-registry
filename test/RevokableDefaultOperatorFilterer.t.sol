// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableDefaultOperatorFilterer} from "src/RevokableDefaultOperatorFilterer.sol";
import {RevokableOperatorFilterer} from "src/RevokableOperatorFilterer.sol";
import {BaseRegistryTest} from "./BaseRegistryTest.sol";
import {RevokableDefaultFilterer} from "./helpers/RevokableDefaultFilterer.sol";

contract RevokableDefaultOperatorFiltererTest is BaseRegistryTest {
    RevokableDefaultFilterer filterer;
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;
    address notFiltered;
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function setUp() public override {
        super.setUp();
        notFiltered = makeAddr("not filtered");
        vm.startPrank(DEFAULT_SUBSCRIPTION);
        registry.register(DEFAULT_SUBSCRIPTION);

        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), filteredAddress, true);
        filteredCodeHashAddress = makeAddr("filtered code hash");
        bytes memory code = hex"deadbeef";
        filteredCodeHash = keccak256(code);
        registry.updateCodeHash(address(DEFAULT_SUBSCRIPTION), filteredCodeHash, true);
        vm.etch(filteredCodeHashAddress, code);

        filterer = new RevokableDefaultFilterer();
        vm.stopPrank();
    }

    function testFilter() public {
        assertTrue(filterer.filterTest(notFiltered));
        vm.startPrank(filteredAddress);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        filterer.filterTest(address(0));
        vm.stopPrank();
        vm.startPrank(filteredCodeHashAddress);
        vm.expectRevert(abi.encodeWithSelector(CodeHashFiltered.selector, filteredCodeHashAddress, filteredCodeHash));
        filterer.filterTest(address(0));
    }

    function testRevoke() public {
        vm.startPrank(filteredAddress);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        filterer.filterTest(address(0));
        vm.stopPrank();

        vm.startPrank(DEFAULT_SUBSCRIPTION);
        filterer.updateOperatorFilterRegistryAddress(address(0));
        assertFalse(filterer.isOperatorFilterRegistryRevoked());
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSignature("OnlyOwner()"));
        filterer.updateOperatorFilterRegistryAddress(address(0));

        vm.startPrank(DEFAULT_SUBSCRIPTION);
        filterer.revokeOperatorFilterRegistry();

        vm.expectRevert(abi.encodeWithSignature("RegistryHasBeenRevoked()"));
        filterer.updateOperatorFilterRegistryAddress(address(0));
        vm.stopPrank();

        vm.startPrank(filteredAddress);
        assertTrue(filterer.filterTest(address(0)));
        vm.stopPrank();
    }
}
