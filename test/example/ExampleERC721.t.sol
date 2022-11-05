// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ExampleERC721} from "../../src/example/ExampleERC721.sol";
import {DefaultOperatorFilterer} from "../../src/DefaultOperatorFilterer.sol";
import {OperatorFilterer} from "../../src/OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Test} from "forge-std/Test.sol";
import {OperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents} from "../../src/OperatorFilterRegistry.sol";

contract DefaultFilterer is DefaultOperatorFilterer, Ownable {
    constructor() DefaultOperatorFilterer() {}

    function filterTest(address addr) public onlyAllowedOperator returns (bool) {
        return true;
    }
}

contract ExampleERC721Test is Test, OperatorFilterRegistryErrorsAndEvents {
    ExampleERC721 example;
    OperatorFilterRegistry registry;
    address filteredAddress;

    address constant DEFAULT_OPERATOR_FILTER_REGISTRY = address(0xdeadbeef);
    address constant DEFAULT_SUBSCRIPTION = address(0xdadb0d);

    function setUp() public {
        vm.etch(DEFAULT_OPERATOR_FILTER_REGISTRY, address(new OperatorFilterRegistry()).code);
        registry = OperatorFilterRegistry(DEFAULT_OPERATOR_FILTER_REGISTRY);

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
