// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BaseRegistryTest} from "./BaseRegistryTest.sol";
import {OperatorFilterer} from "../src/OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract Filterer is OperatorFilterer, Ownable {
    constructor(address registry) OperatorFilterer(address(0), false) {}

    function testFilter(address from) public view onlyAllowedOperator(from) returns (bool) {
        return true;
    }
}

contract Owned is Ownable {}

contract OwnableReverter {
    error Bad();

    function owner() public pure returns (address) {
        revert Bad();
    }
}

contract OperatorFilterRegistryTest is BaseRegistryTest {
    Filterer filterer;
    Ownable owned;
    OwnableReverter reverter;

    function setUp() public override {
        super.setUp();
        filterer = new Filterer(address(registry));
        owned = new Owned();
        reverter = new OwnableReverter();
    }

    function testOnlyAddressOrOwner() public {
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(NotOwnable.selector));
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        registry.register(address(owned));
        vm.expectRevert(abi.encodeWithSelector(OwnableReverter.Bad.selector));
        registry.register(address(reverter));
    }

    function testRegister_constructor() public {
        vm.expectEmit(true, false, false, false, address(registry));
        emit RegistrationUpdated(address(this), true);
        registry.register(address(this));

        assertTrue(registry.isRegistered(address(filterer)));
        assertEq(registry.subscriptionOf(address(filterer)), address(0));
    }

    function testRegister_onlyAddressOrOwner() public {
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        registry.register(address(filterer));
    }

    function testRegister_alreadyRegistered() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(AlreadyRegistered.selector));
        registry.register(address(this));
    }

    function testRegisterAndSubscribe() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        vm.expectEmit(true, false, false, false, address(registry));
        emit RegistrationUpdated(address(this), true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(address(this), subscription, true);
        registry.registerAndSubscribe(address(this), subscription);
        assertEq(registry.subscribers(subscription).length, 1);
        assertEq(registry.subscribers(subscription)[0], address(this));
        assertEq(registry.subscriberAt(subscription, 0), address(this));
    }

    function testRegisterAndSubscribe_OnlyAddressOrOwner() public {
        address subscription = makeAddr("subscription");
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        registry.registerAndSubscribe(address(owned), subscription);
    }

    function testRegisterAndSubscribe_AlreadyRegistered() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(AlreadyRegistered.selector));
        registry.registerAndSubscribe(address(this), makeAddr("subscription"));
    }

    function testRegisterAndSubscribe_CannotRegisterToSelf() public {
        vm.expectRevert(abi.encodeWithSelector(CannotSubscribeToSelf.selector));
        registry.registerAndSubscribe(address(this), address(this));
    }

    function testRegisterAndSubscribe_NotRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, makeAddr("subscription")));
        registry.registerAndSubscribe(address(this), makeAddr("subscription"));
    }

    function testRegisterAndSubscribe_CannotSubscribeToRegistrantWithSubscription() public {
        address subscription = makeAddr("subscription");
        address superSubscription = makeAddr("superSubscription");
        vm.prank(superSubscription);
        registry.register(superSubscription);
        vm.prank(subscription);
        registry.registerAndSubscribe(subscription, superSubscription);
        vm.expectRevert(abi.encodeWithSelector(CannotSubscribeToRegistrantWithSubscription.selector, subscription));
        registry.registerAndSubscribe(address(this), subscription);
    }

    function testRegisterAndCopyEntries() public {
        registry.register(address(this));
        registry.updateOperator(address(this), makeAddr("operator"), true);
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), true);

        vm.expectEmit(true, true, true, false, address(registry));
        emit OperatorUpdated(address(filterer), makeAddr("operator"), true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit CodeHashUpdated(address(filterer), bytes32(bytes4(0xdeadbeef)), true);

        registry.copyEntriesOf(address(filterer), address(this));

        assertEq(registry.subscribers(address(this)).length, 0);
        assertTrue(registry.isRegistered(address(filterer)));
        assertEq(registry.filteredOperatorAt(address(filterer), 0), makeAddr("operator"));
        assertEq(registry.filteredCodeHashAt(address(filterer), 0), bytes32(bytes4(0xdeadbeef)));
    }

    function testRegisterAndCopyEntries_OnlyAddressOrOwner() public {
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        registry.registerAndCopyEntries(address(filterer), address(this));
    }

    function testRegisterAndCopyEntries_CannotCopyFromSelf() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(CannotCopyFromSelf.selector));
        registry.registerAndCopyEntries(address(this), address(this));
    }

    function testRegisterAndCopyEntries_AlreadyRegistered() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(AlreadyRegistered.selector));
        registry.registerAndCopyEntries(address(this), makeAddr("not registered but fail fast"));
    }

    function testRegisterAndCopyEntries_NotRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, makeAddr("registrant")));
        registry.registerAndCopyEntries(address(this), makeAddr("registrant"));
    }

    function testUpdateOperator() public {
        registry.register(address(this));
        vm.expectEmit(true, true, true, false, address(registry));
        emit OperatorUpdated(address(this), makeAddr("operator"), true);
        registry.updateOperator(address(this), makeAddr("operator"), true);
        assertTrue(registry.isOperatorFiltered(address(this), makeAddr("operator")));
        assertEq(registry.filteredOperatorAt(address(this), 0), makeAddr("operator"));
    }

    function testUpdateOperator_OnlyAddressOrOwner() public {
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        registry.updateOperator(address(owned), makeAddr("operator"), true);
    }

    function testUpdateOperator_notRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, address(this)));
        registry.updateOperator(address(this), makeAddr("operator"), true);
    }

    function testUpdateOperator_CannotUpdateWhileSubscribed() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        registry.registerAndSubscribe(address(this), subscription);
        vm.expectRevert(abi.encodeWithSelector(CannotUpdateWhileSubscribed.selector, subscription));
        registry.updateOperator(address(this), makeAddr("operator"), true);
    }

    function testUpdateOperator_unfilter() public {
        registry.register(address(this));
        registry.updateOperator(address(this), makeAddr("operator"), true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit OperatorUpdated(address(this), makeAddr("operator"), false);
        registry.updateOperator(address(this), makeAddr("operator"), false);
        assertFalse(registry.isOperatorFiltered(address(this), makeAddr("operator")));
        vm.expectRevert();
        registry.filteredOperatorAt(address(this), 0);
    }

    function testUpdateOperator_AddressNotFiltered() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(AddressNotFiltered.selector, makeAddr("operator")));
        registry.updateOperator(address(this), makeAddr("operator"), false);
    }

    function testUpdateOperator_AddressAlreadyFiltered() public {
        registry.register(address(this));
        registry.updateOperator(address(this), makeAddr("operator"), true);
        vm.expectRevert(abi.encodeWithSelector(AddressAlreadyFiltered.selector, makeAddr("operator")));
        registry.updateOperator(address(this), makeAddr("operator"), true);
    }

    function testUpdateCodeHash() public {
        registry.register(address(this));
        vm.expectEmit(true, true, true, false, address(registry));
        emit CodeHashUpdated(address(this), bytes32(bytes4(0xdeadbeef)), true);
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), true);
        assertTrue(registry.isCodeHashFiltered(address(this), bytes32(bytes4(0xdeadbeef))));
        assertEq(registry.filteredCodeHashAt(address(this), 0), bytes32(bytes4(0xdeadbeef)));
    }

    function testUpdateCodeHash_OnlyAddressOrOwner() public {
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        registry.updateCodeHash(address(owned), bytes32(bytes4(0xdeadbeef)), true);
    }

    function testUpdateCodeHash_CannotFilterEOAs() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(CannotFilterEOAs.selector));
        registry.updateCodeHash(address(this), keccak256(""), true);
    }

    function testUpdateCodeHash_NotRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, address(this)));
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), true);
    }

    function testUpdateCodeHash_CannotUpdateWhileSubscribed() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        registry.registerAndSubscribe(address(this), subscription);
        vm.expectRevert(abi.encodeWithSelector(CannotUpdateWhileSubscribed.selector, subscription));
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), true);
    }

    function testUpdateCodeHash_unfilter() public {
        registry.register(address(this));
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit CodeHashUpdated(address(this), bytes32(bytes4(0xdeadbeef)), false);
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), false);
        assertFalse(registry.isCodeHashFiltered(address(this), bytes32(bytes4(0xdeadbeef))));
        vm.expectRevert();
        registry.filteredCodeHashAt(address(this), 0);
    }

    function testUpdateCodeHash_CodeHashNotFiltered() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(CodeHashNotFiltered.selector, bytes32(bytes4(0xdeadbeef))));
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), false);
    }

    function testUpdateCodeHash_CodeHashAlreadyFiltered() public {
        registry.register(address(this));
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), true);
        vm.expectRevert(abi.encodeWithSelector(CodeHashAlreadyFiltered.selector, bytes32(bytes4(0xdeadbeef))));
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), true);
    }

    function testUpdateOperators() public {
        registry.register(address(this));

        address[] memory operator = new address[](2);
        operator[0] = makeAddr("operator1");
        operator[1] = makeAddr("operator2");
        vm.expectEmit(true, true, false, false, address(registry));
        emit OperatorsUpdated(address(this), operator, true);
        registry.updateOperators(address(this), operator, true);
        assertTrue(registry.isOperatorFiltered(address(this), operator[0]));
        assertTrue(registry.isOperatorFiltered(address(this), operator[1]));
        assertEq(registry.filteredOperatorAt(address(this), 0), operator[0]);
        assertEq(registry.filteredOperatorAt(address(this), 1), operator[1]);
    }

    function testUpdateOperators_OnlyAddressOrOwner() public {
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        address[] memory operator = new address[](1);
        operator[0] = makeAddr("operator1");
        registry.updateOperators(address(owned), operator, true);
    }

    function testUpdateOperators_notRegistered() public {
        address[] memory operator = new address[](2);
        operator[0] = makeAddr("operator1");
        operator[1] = makeAddr("operator2");
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, address(this)));
        registry.updateOperators(address(this), operator, true);
    }

    function testUpdateOperators_CannotUpdateWhileSubscribed() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        registry.registerAndSubscribe(address(this), subscription);
        address[] memory operator = new address[](2);
        operator[0] = makeAddr("operator1");
        operator[1] = makeAddr("operator2");
        vm.expectRevert(abi.encodeWithSelector(CannotUpdateWhileSubscribed.selector, subscription));
        registry.updateOperators(address(this), operator, true);
    }

    function testUpdateOperators_unfilter() public {
        registry.register(address(this));
        registry.updateOperator(address(this), makeAddr("operator1"), true);
        registry.updateOperator(address(this), makeAddr("operator2"), true);

        address[] memory operator = new address[](2);
        operator[0] = makeAddr("operator1");
        operator[1] = makeAddr("operator2");
        vm.expectEmit(true, true, true, false, address(registry));
        emit OperatorsUpdated(address(this), operator, false);
        registry.updateOperators(address(this), operator, false);
        assertFalse(registry.isOperatorFiltered(address(this), operator[0]));
        assertFalse(registry.isOperatorFiltered(address(this), operator[1]));
        vm.expectRevert();
        registry.filteredOperatorAt(address(this), 0);
    }

    function testUpdateOperators_AddressNotFiltered() public {
        registry.register(address(this));
        address[] memory operator = new address[](2);
        operator[0] = makeAddr("operator1");
        operator[1] = makeAddr("operator2");
        vm.expectRevert(abi.encodeWithSelector(AddressNotFiltered.selector, makeAddr("operator1")));
        registry.updateOperators(address(this), operator, false);
    }

    function testUpdateOperators_AddressAlreadyFiltered() public {
        registry.register(address(this));
        registry.updateOperator(address(this), makeAddr("operator1"), true);
        registry.updateOperator(address(this), makeAddr("operator2"), true);
        address[] memory operator = new address[](2);
        operator[0] = makeAddr("operator1");
        operator[1] = makeAddr("operator2");
        vm.expectRevert(abi.encodeWithSelector(AddressAlreadyFiltered.selector, makeAddr("operator1")));
        registry.updateOperators(address(this), operator, true);
    }

    function testUpdateCodeHashes() public {
        registry.register(address(this));
        bytes32[] memory codeHash = new bytes32[](2);
        codeHash[0] = bytes32(bytes4(0xdeadbeef));
        codeHash[1] = bytes32(bytes4(0xdeafbeef));
        vm.expectEmit(true, true, false, false, address(registry));
        emit CodeHashesUpdated(address(this), codeHash, true);
        registry.updateCodeHashes(address(this), codeHash, true);
    }

    function testUpdateCodeHashes_OnlyAddressOrOwner() public {
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        bytes32[] memory codeHash = new bytes32[](1);
        codeHash[0] = bytes32(bytes4(0xdeadbeef));
        registry.updateCodeHashes(address(owned), codeHash, true);
    }

    function testUpdateCodeHashes_notRegistered() public {
        bytes32[] memory codeHash = new bytes32[](2);
        codeHash[0] = bytes32(bytes4(0xdeadbeef));
        codeHash[1] = bytes32(bytes4(0xdeafbeef));
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, address(this)));
        registry.updateCodeHashes(address(this), codeHash, true);
    }

    function testUpdateCodeHashes_CannotUpdateWhileSubscribed() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        registry.registerAndSubscribe(address(this), subscription);
        bytes32[] memory codeHash = new bytes32[](2);
        codeHash[0] = bytes32(bytes4(0xdeadbeef));
        codeHash[1] = bytes32(bytes4(0xdeafbeef));
        vm.expectRevert(abi.encodeWithSelector(CannotUpdateWhileSubscribed.selector, subscription));
        registry.updateCodeHashes(address(this), codeHash, true);
    }

    function testUpdateCodeHashes_unfilter() public {
        registry.register(address(this));
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), true);
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeafbeef)), true);

        bytes32[] memory codeHash = new bytes32[](2);
        codeHash[0] = bytes32(bytes4(0xdeadbeef));
        codeHash[1] = bytes32(bytes4(0xdeafbeef));
        vm.expectEmit(true, true, false, false, address(registry));
        emit CodeHashesUpdated(address(this), codeHash, false);
        registry.updateCodeHashes(address(this), codeHash, false);
        assertFalse(registry.isCodeHashFiltered(address(this), codeHash[0]));
        assertFalse(registry.isCodeHashFiltered(address(this), codeHash[1]));
        vm.expectRevert();
        registry.filteredCodeHashAt(address(this), 0);
    }

    function testUpdateCodeHashes_CodeHashNotFiltered() public {
        registry.register(address(this));
        bytes32[] memory codeHash = new bytes32[](2);
        codeHash[0] = bytes32(bytes4(0xdeadbeef));
        codeHash[1] = bytes32(bytes4(0xdeafbeef));
        vm.expectRevert(abi.encodeWithSelector(CodeHashNotFiltered.selector, bytes32(bytes4(0xdeadbeef))));
        registry.updateCodeHashes(address(this), codeHash, false);
    }

    function testUpdateCodeHashes_CannotFilterEOAs() public {
        registry.register(address(this));
        bytes32[] memory codeHash = new bytes32[](2);
        codeHash[0] = bytes32(bytes4(0xdeadbeef));
        codeHash[1] = keccak256("");
        vm.expectRevert(CannotFilterEOAs.selector);
        registry.updateCodeHashes(address(this), codeHash, true);
    }

    function testUpdateCodeHashes_CodeHashAlreadyFiltered() public {
        registry.register(address(this));
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeadbeef)), true);
        registry.updateCodeHash(address(this), bytes32(bytes4(0xdeafbeef)), true);
        bytes32[] memory codeHash = new bytes32[](2);
        codeHash[0] = bytes32(bytes4(0xdeadbeef));
        codeHash[1] = bytes32(bytes4(0xdeafbeef));
        vm.expectRevert(abi.encodeWithSelector(CodeHashAlreadyFiltered.selector, bytes32(bytes4(0xdeadbeef))));
        registry.updateCodeHashes(address(this), codeHash, true);
    }

    function testSubscribe() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        registry.register(address(this));
        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(address(this), subscription, true);
        registry.subscribe(address(this), subscription);

        assertEq(registry.subscriptionOf(address(this)), subscription);
        assertEq(registry.subscribers(subscription).length, 1);
        assertEq(registry.subscribers(subscription)[0], address(this));
        assertEq(registry.subscriberAt(subscription, 0), address(this));
    }

    function testSubscribe_OnlyAddressOrOwner() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        registry.subscribe(address(owned), subscription);
    }

    function testSubscribe_CannotSubscribeToSelf() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(CannotSubscribeToSelf.selector));
        registry.subscribe(address(this), address(this));
    }

    function testSubscribe_CannotSubscribeToZeroAddress() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(CannotSubscribeToZeroAddress.selector));
        registry.subscribe(address(this), address(0));
    }

    function testSubscribe_notRegistered() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, address(this)));
        registry.subscribe(address(this), subscription);
    }

    function testSubscribe_AlreadySubscribed() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        registry.register(address(this));
        registry.subscribe(address(this), subscription);
        vm.expectRevert(abi.encodeWithSelector(AlreadySubscribed.selector, subscription));
        registry.subscribe(address(this), subscription);
    }

    function testSubscribe_SubscriptionNotRegistered() public {
        registry.register(address(this));
        address subscription = makeAddr("subscription");
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, subscription));
        registry.subscribe(address(this), subscription);
    }

    function testSubscribe_removeOldSubscription() public {
        address oldSubscription = makeAddr("oldSubscription");
        vm.prank(oldSubscription);
        registry.register(oldSubscription);
        registry.register(address(this));
        registry.subscribe(address(this), oldSubscription);

        address newSubscription = makeAddr("newSubscription");
        vm.prank(newSubscription);
        registry.register(newSubscription);
        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(address(this), oldSubscription, false);
        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(address(this), newSubscription, true);
        registry.subscribe(address(this), newSubscription);

        assertEq(registry.subscriptionOf(address(this)), newSubscription);
        assertEq(registry.subscribers(oldSubscription).length, 0);
        assertEq(registry.subscribers(newSubscription).length, 1);
        assertEq(registry.subscribers(newSubscription)[0], address(this));
        assertEq(registry.subscriberAt(newSubscription, 0), address(this));
    }

    function testSubscribe_CannotSubscribeToRegistrantWithSubscription() public {
        address subscription = makeAddr("subscription");
        address superSubscription = makeAddr("superSubscription");
        vm.prank(superSubscription);
        registry.register(superSubscription);
        vm.prank(subscription);
        registry.registerAndSubscribe(subscription, superSubscription);
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(CannotSubscribeToRegistrantWithSubscription.selector, subscription));
        registry.subscribe(address(this), subscription);
    }

    function testUnsubscribe() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        registry.register(address(this));
        registry.subscribe(address(this), subscription);

        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(address(this), subscription, false);
        registry.unsubscribe(address(this), false);

        assertEq(registry.subscriptionOf(address(this)), address(0));
        assertEq(registry.subscribers(subscription).length, 0);
        assertEq(registry.subscriptionOf(address(this)), address(0));
    }

    function testUnsubscribe_notRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, address(this)));
        registry.unregister(address(this));
    }

    function testUnsubscribe_onlyAddressOrOwner() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        registry.register(address(this));
        registry.subscribe(address(this), subscription);

        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        registry.unsubscribe(address(owned), false);
    }

    function testUnsubscribe_copyExistingEntries() public {
        address subscription = makeAddr("subscription");
        address operator = makeAddr("operator");
        bytes32 codeHash = bytes32(bytes4(0xdeadbeef));
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateOperator(subscription, operator, true);
        registry.updateCodeHash(subscription, codeHash, true);
        vm.stopPrank();
        registry.register(address(this));
        registry.subscribe(address(this), subscription);

        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(address(this), subscription, false);
        vm.expectEmit(true, true, true, false, address(registry));
        emit OperatorUpdated(address(this), operator, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit CodeHashUpdated(address(this), codeHash, true);
        registry.unsubscribe(address(this), true);

        assertEq(registry.subscriptionOf(address(this)), address(0));
    }

    function testUnsubscribe_NotRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, address(this)));
        registry.unsubscribe(address(this), false);
    }

    function testUnsubscribe_NotSubscribed() public {
        registry.register(address(this));
        vm.expectRevert(abi.encodeWithSelector(NotSubscribed.selector));
        registry.unsubscribe(address(this), false);
    }

    function testCopyEntriesOf() public {
        address subscription = makeAddr("subscription");
        address operator = makeAddr("operator");
        address duplicateOperator = makeAddr("duplicateOperator");
        bytes32 codeHash = bytes32(bytes4(0xdeadbeef));
        bytes32 duplicateCodeHash = bytes32(bytes5(0xdeadbeef22));
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateOperator(subscription, operator, true);
        registry.updateOperator(subscription, duplicateOperator, true);
        registry.updateCodeHash(subscription, codeHash, true);
        registry.updateCodeHash(subscription, duplicateCodeHash, true);
        vm.stopPrank();
        // test that it does not throw errors for duplicate entries
        // and that events are not emitted for them
        registry.register(address(this));
        registry.updateOperator(address(this), duplicateOperator, true);
        registry.updateCodeHash(address(this), duplicateCodeHash, true);

        vm.expectEmit(true, true, true, false, address(registry));
        emit OperatorUpdated(address(this), operator, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit CodeHashUpdated(address(this), codeHash, true);
        registry.copyEntriesOf(address(this), subscription);

        assertEq(registry.filteredOperators(address(this)).length, 2);
        assertEq(registry.filteredOperators(address(this))[0], duplicateOperator);
        assertEq(registry.filteredOperatorAt(address(this), 0), duplicateOperator);
        assertEq(registry.filteredOperators(address(this))[1], operator);
        assertEq(registry.filteredOperatorAt(address(this), 1), operator);

        assertEq(registry.filteredCodeHashes(address(this)).length, 2);
        assertEq(registry.filteredCodeHashes(address(this))[0], duplicateCodeHash);
        assertEq(registry.filteredCodeHashAt(address(this), 0), duplicateCodeHash);
        assertEq(registry.filteredCodeHashes(address(this))[1], codeHash);
        assertEq(registry.filteredCodeHashAt(address(this), 1), codeHash);
    }

    function testCopyEntriesOf_cannotCopySelf() public {
        registry.register(address(this));
        vm.expectRevert(CannotCopyFromSelf.selector);
        registry.copyEntriesOf(address(this), address(this));
    }

    function testCopyEntriesOf_OnlyAddressOrOwner() public {
        address subscription = makeAddr("subscription");
        vm.startPrank(subscription);
        registry.register(subscription);
        vm.stopPrank();
        registry.register(address(this));

        vm.startPrank(makeAddr("not owner"));
        vm.expectRevert(abi.encodeWithSelector(OnlyAddressOrOwner.selector));
        registry.copyEntriesOf(address(owned), subscription);
    }

    function testCopyEntriesOf_NotRegistered() public {
        address subscription = makeAddr("subscription");
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, address(this)));
        registry.copyEntriesOf(address(this), subscription);
    }

    function testCopyEntriesOf_CannotUpdateWhileSubscribed() public {
        address subscription = makeAddr("subscription");
        address operator = makeAddr("operator");
        bytes32 codeHash = bytes32(bytes4(0xdeadbeef));
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateOperator(subscription, operator, true);
        registry.updateCodeHash(subscription, codeHash, true);
        vm.stopPrank();
        registry.register(address(this));
        registry.subscribe(address(this), subscription);

        vm.expectRevert(abi.encodeWithSelector(CannotUpdateWhileSubscribed.selector, subscription));
        registry.copyEntriesOf(address(this), subscription);
    }

    function testCopyEntriesOf_NotRegistered_registrant() public {
        registry.register(address(this));
        address subscription = makeAddr("subscription");
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, subscription));
        registry.copyEntriesOf(address(this), subscription);
    }

    function testCodeHashOf() public {
        address toCheck = makeAddr("toCheck");
        bytes memory code = hex"deadbeef";
        bytes32 codeHash = keccak256(code);
        vm.etch(toCheck, code);
        assertEq(registry.codeHashOf(toCheck), codeHash);
    }

    function testIsCodeHashOfFiltered() public {
        address toCheck = makeAddr("toCheck");
        bytes memory code = hex"deadbeef";
        bytes32 codeHash = keccak256(code);
        vm.etch(toCheck, code);
        registry.register(address(this));
        registry.updateCodeHash(address(this), codeHash, true);
        assertTrue(registry.isCodeHashOfFiltered(address(this), toCheck));
        assertFalse(registry.isCodeHashOfFiltered(address(this), makeAddr("not filtered")));
    }

    function testIsCodeHashOfFiltered_subscription() public {
        address toCheck = makeAddr("toCheck");
        bytes memory code = hex"deadbeef";
        bytes32 codeHash = keccak256(code);
        vm.etch(toCheck, code);
        address subscription = makeAddr("subscription");
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateCodeHash(subscription, codeHash, true);
        vm.stopPrank();
        registry.registerAndSubscribe(address(this), subscription);
        assertTrue(registry.isCodeHashOfFiltered(address(this), toCheck));
        assertFalse(registry.isCodeHashOfFiltered(address(this), makeAddr("not filtered")));
    }

    function testIsCodeHashFiltered_subscription() public {
        address toCheck = makeAddr("toCheck");
        bytes memory code = hex"deadbeef";
        bytes32 codeHash = keccak256(code);
        vm.etch(toCheck, code);
        address subscription = makeAddr("subscription");
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateCodeHash(subscription, codeHash, true);
        vm.stopPrank();
        registry.registerAndSubscribe(address(this), subscription);
        assertTrue(registry.isCodeHashFiltered(address(this), codeHash));
        assertFalse(registry.isCodeHashFiltered(address(this), bytes32(bytes4(0xdeadbeef))));
    }

    function testIsOperatorFiltered_subscription() public {
        address operator = makeAddr("operator");
        address subscription = makeAddr("subscription");
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateOperator(subscription, operator, true);
        vm.stopPrank();
        registry.registerAndSubscribe(address(this), subscription);
        assertTrue(registry.isOperatorFiltered(address(this), operator));
        assertFalse(registry.isOperatorFiltered(address(this), makeAddr("not filtered")));
    }

    function testFilteredOperators_subscription() public {
        address operator = makeAddr("operator");
        address subscription = makeAddr("subscription");
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateOperator(subscription, operator, true);
        vm.stopPrank();
        registry.registerAndSubscribe(address(this), subscription);
        assertEq(registry.filteredOperators(address(this)).length, 1);
        assertEq(registry.filteredOperators(address(this))[0], operator);
        assertEq(registry.filteredOperatorAt(address(this), 0), operator);
    }

    function testFilteredCodeHashes_subscription() public {
        address toCheck = makeAddr("toCheck");
        bytes memory code = hex"deadbeef";
        bytes32 codeHash = keccak256(code);
        vm.etch(toCheck, code);
        address subscription = makeAddr("subscription");
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateCodeHash(subscription, codeHash, true);
        vm.stopPrank();
        registry.registerAndSubscribe(address(this), subscription);
        assertEq(registry.filteredCodeHashes(address(this)).length, 1);
        assertEq(registry.filteredCodeHashes(address(this))[0], codeHash);
        assertEq(registry.filteredCodeHashAt(address(this), 0), codeHash);
    }

    function testFilteredOperatorAt_subscription() public {
        address operator = makeAddr("operator");
        address subscription = makeAddr("subscription");
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateOperator(subscription, operator, true);
        vm.stopPrank();
        registry.registerAndSubscribe(address(this), subscription);
        assertEq(registry.filteredOperatorAt(address(this), 0), operator);
    }

    function testFilteredCodeHashAt_subscription() public {
        address toCheck = makeAddr("toCheck");
        bytes memory code = hex"deadbeef";
        bytes32 codeHash = keccak256(code);
        vm.etch(toCheck, code);
        address subscription = makeAddr("subscription");
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateCodeHash(subscription, codeHash, true);
        vm.stopPrank();
        registry.registerAndSubscribe(address(this), subscription);
        assertEq(registry.filteredCodeHashAt(address(this), 0), codeHash);
    }

    function testIsRegistered() public {
        registry.register(address(this));
        assertTrue(registry.isRegistered(address(this)));
        assertFalse(registry.isRegistered(makeAddr("not registered")));
    }

    function testIsOperatorAllowed_NotRegistered() public {
        assertTrue(registry.isOperatorAllowed(address(this), makeAddr("allowed")));
    }

    function testIsOperatorAllowed() public {
        address operator = makeAddr("operator");
        address toCheck = makeAddr("toCheck");
        bytes memory code = hex"deadbeef";
        bytes32 codeHash = keccak256(code);
        vm.etch(toCheck, code);
        registry.register(address(this));
        registry.updateOperator(address(this), operator, true);
        registry.updateCodeHash(address(this), codeHash, true);

        assertTrue(registry.isOperatorAllowed(address(this), makeAddr("allowed")));
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, address(operator)));
        registry.isOperatorAllowed(address(this), operator);
        vm.expectRevert(abi.encodeWithSelector(CodeHashFiltered.selector, address(toCheck), codeHash));
        registry.isOperatorAllowed(address(this), toCheck);
    }

    function testIsOperatorAllowed_subscription() public {
        address operator = makeAddr("operator");
        address toCheck = makeAddr("toCheck");
        bytes memory code = hex"deadbeef";
        bytes32 codeHash = keccak256(code);
        vm.etch(toCheck, code);
        address subscription = makeAddr("subscription");
        vm.startPrank(subscription);
        registry.register(subscription);
        registry.updateOperator(subscription, operator, true);
        registry.updateCodeHash(subscription, codeHash, true);
        vm.stopPrank();
        registry.registerAndSubscribe(address(this), subscription);

        assertTrue(registry.isOperatorAllowed(address(this), makeAddr("allowed")));
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, address(operator)));
        registry.isOperatorAllowed(address(this), operator);
        vm.expectRevert(abi.encodeWithSelector(CodeHashFiltered.selector, address(toCheck), codeHash));
        registry.isOperatorAllowed(address(this), toCheck);
    }

    function testUnregister() public {
        address subscription = makeAddr("subscription");
        vm.prank(subscription);
        registry.register(subscription);
        registry.registerAndSubscribe(address(this), subscription);
        assertTrue(registry.isRegistered(address(this)));
        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(address(this), subscription, false);
        vm.expectEmit(true, true, true, false, address(registry));
        emit RegistrationUpdated(address(this), false);
        registry.unregister(address(this));
        assertFalse(registry.isRegistered(address(this)));
        assertEq(registry.subscribers(subscription).length, 0);
    }

    function testSubscriptionOf_notRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(NotRegistered.selector, address(this)));
        registry.subscriptionOf(address(this));
    }
}
