// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseRegistryTest} from "../BaseRegistryTest.sol";
import {RevokableUpgradeableFilterer} from "../helpers/RevokableUpgradeableFilterer.sol";

contract RevokableUpgradeableOperatorFiltererTest is BaseRegistryTest {
    RevokableUpgradeableFilterer filterer;
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;
    address notFiltered;

    function setUp() public virtual override {
        super.setUp();
        notFiltered = makeAddr("not filtered");
        filterer = new RevokableUpgradeableFilterer();
        filterer.init(address(0), false);
        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(filterer), filteredAddress, true);
        filteredCodeHashAddress = makeAddr("filtered code hash");
        bytes memory code = hex"deadbeef";
        filteredCodeHash = keccak256(code);
        registry.updateCodeHash(address(filterer), filteredCodeHash, true);
        vm.etch(filteredCodeHashAddress, code);
    }

    function testRevoke() public {
        filterer.revokeOperatorFilterRegistry();
        vm.prank(filteredAddress);
        assertTrue(filterer.testFilter(address(0)));

        assertTrue(filterer.isOperatorFilterRegistryRevoked());

        vm.expectRevert(abi.encodeWithSignature("AlreadyRevoked()"));
        filterer.revokeOperatorFilterRegistry();

        vm.prank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSignature("OnlyOwner()"));
        filterer.revokeOperatorFilterRegistry();
    }
}
