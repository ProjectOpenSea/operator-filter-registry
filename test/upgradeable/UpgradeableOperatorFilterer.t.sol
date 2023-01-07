// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseRegistryTest} from "../BaseRegistryTest.sol";
import {UpgradeableFilterer} from "../helpers/UpgradeableFilterer.sol";

contract UpgradeableOperatorFiltererTest is BaseRegistryTest {
    UpgradeableFilterer filterer;
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function setUp() public virtual override {
        super.setUp();
        filterer = new UpgradeableFilterer();
        vm.startPrank(DEFAULT_SUBSCRIPTION);
        registry.register(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(DEFAULT_SUBSCRIPTION, makeAddr("operator"), true);
        vm.stopPrank();
    }

    function testInit_copy() public {
        filterer.init(DEFAULT_SUBSCRIPTION, false);
        assertTrue(registry.isOperatorFiltered(address(filterer), makeAddr("operator")));
    }

    function testInit_noSubscription() public {
        filterer.init(address(0), false);
        assertTrue(registry.isRegistered(address(filterer)));
    }

    function testInit_registered() public {
        vm.prank(address(filterer));
        registry.register(address(filterer));
        filterer.init(DEFAULT_SUBSCRIPTION, true);
        // should not be subscribed since already registered
        assertEq(registry.subscriptionOf(address(filterer)), address(0));
    }
}
