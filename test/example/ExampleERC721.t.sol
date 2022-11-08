// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ExampleERC721} from "../../src/example/ExampleERC721.sol";
import {DefaultOperatorFilterer721} from "../../src/DefaultOperatorFilterer721.sol";
import {OperatorFilterer721} from "../../src/OperatorFilterer721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Test} from "forge-std/Test.sol";
import {OperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents} from "../../src/OperatorFilterRegistry.sol";
import {BaseRegistryTest} from "../BaseRegistryTest.sol";

contract TestableExampleERC721 is ExampleERC721 {
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract ExampleERC721Test is BaseRegistryTest {
    TestableExampleERC721 example;
    address filteredAddress;

    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function setUp() public override {
        super.setUp();

        vm.startPrank(DEFAULT_SUBSCRIPTION);
        registry.register(DEFAULT_SUBSCRIPTION);

        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), filteredAddress, true);

        example = new TestableExampleERC721();
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

    function testOwnerExclusion() public {
        address alice = address(0xA11CE);
        example.mint(alice, 1);

        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.prank(alice);
        example.transferFrom(alice, makeAddr("to"), 1);
    }
}
