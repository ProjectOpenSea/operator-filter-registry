// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ExampleERC721} from "../../src/example/ExampleERC721.sol";
import {DefaultOperatorFilterer} from "../../src/DefaultOperatorFilterer.sol";
import {OperatorFilterer} from "../../src/OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Test} from "forge-std/Test.sol";
import {OperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents} from "../../src/OperatorFilterRegistry.sol";
import {BaseRegistryTest} from "../BaseRegistryTest.sol";

contract ExampleERC721Test is BaseRegistryTest {
    ExampleERC721 example;
    address filteredAddress;

    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function setUp() public override {
        super.setUp();

        vm.startPrank(DEFAULT_SUBSCRIPTION);
        registry.register(DEFAULT_SUBSCRIPTION);

        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), filteredAddress, true);

        example = new ExampleERC721();
        vm.stopPrank();
    }

    function testFilter() public {
        vm.startPrank(address(filteredAddress));
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        example.transferFrom(makeAddr("from"), makeAddr("to"), 1);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        example.safeTransferFrom(makeAddr("from"), makeAddr("to"), 1);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        example.safeTransferFrom(makeAddr("from"), makeAddr("to"), 1, "");
    }
}
