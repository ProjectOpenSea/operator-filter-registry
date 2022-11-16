// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ExampleERC1155} from "../../src/example/ExampleERC1155.sol";
import {BaseRegistryTest} from "../BaseRegistryTest.sol";

contract TestableExampleERC1155 is ExampleERC1155 {
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId, 1, "");
    }
}

contract ExampleERC1155Test is BaseRegistryTest {
    TestableExampleERC1155 example;
    address filteredAddress;

    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function setUp() public override {
        super.setUp();

        vm.startPrank(DEFAULT_SUBSCRIPTION);
        registry.register(DEFAULT_SUBSCRIPTION);

        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), filteredAddress, true);
        vm.stopPrank();

        example = new TestableExampleERC1155();
    }

    function testFilter() public {
        vm.startPrank(address(filteredAddress));
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        example.safeTransferFrom(makeAddr("from"), makeAddr("to"), 1, 1, "");
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        example.safeBatchTransferFrom(makeAddr("from"), makeAddr("to"), ids, amounts, "");
    }

    function testOwnersNotExcluded() public {
        address alice = address(0xA11CE);
        example.mint(alice, 1);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.prank(alice);
        example.safeTransferFrom(alice, makeAddr("to"), 1, 1, "");
    }

    function testOwnersNotExcludedBatch() public {
        address alice = address(0xA11CE);
        example.mint(alice, 1);
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.prank(alice);
        example.safeBatchTransferFrom(alice, makeAddr("to"), ids, amounts, "");
    }

    function testExclusionExceptionDoesNotApplyToOperators() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);
        example.mint(bob, 1);

        vm.prank(bob);
        example.setApprovalForAll(alice, true);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, alice));
        example.safeTransferFrom(bob, makeAddr("to"), 1, 1, "");
    }

    function testExcludeApprovals() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);
        example.mint(bob, 1);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, alice));
        example.setApprovalForAll(alice, true);
    }
}
