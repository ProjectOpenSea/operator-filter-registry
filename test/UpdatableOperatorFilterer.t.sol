// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UpdatableOperatorFilterer} from "../src/UpdatableOperatorFilterer.sol";
import {BaseRegistryTest} from "./BaseRegistryTest.sol";
import {Vm} from "forge-std/Vm.sol";
import {UpdatableFilterer} from "./helpers/UpdatableFilterer.sol";

contract ConcreteUpdatableOperatorFilterer is UpdatableOperatorFilterer {
    address _owner;

    constructor(address registry, address registrant, bool sub) UpdatableOperatorFilterer(registry, registrant, sub) {
        _owner = msg.sender;
    }

    function owner() public view override returns (address) {
        return _owner;
    }
}

contract UpdatableOperatorFiltererTest is BaseRegistryTest {
    UpdatableFilterer filterer;
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;
    address notFiltered;

    function setUp() public override {
        super.setUp();
        notFiltered = makeAddr("not filtered");
        filterer = new UpdatableFilterer(address(registry));
        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(filterer), filteredAddress, true);
        filteredCodeHashAddress = makeAddr("filtered code hash");
        bytes memory code = hex"deadbeef";
        filteredCodeHash = keccak256(code);
        registry.updateCodeHash(address(filterer), filteredCodeHash, true);
        vm.etch(filteredCodeHashAddress, code);
    }

    function testFilter() public {
        assertTrue(filterer.testFilter(notFiltered));
        vm.startPrank(filteredAddress);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        filterer.testFilter(address(0));
        vm.stopPrank();
        vm.startPrank(filteredCodeHashAddress);
        vm.expectRevert(abi.encodeWithSelector(CodeHashFiltered.selector, filteredCodeHashAddress, filteredCodeHash));
        filterer.testFilter(address(0));
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function testConstructory_noSubscribeOrCopy() public {
        vm.recordLogs();
        UpdatableFilterer filterer2 = new UpdatableFilterer(address(registry));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(logs.length, 2);
        assertEq(logs[0].topics[0], keccak256("RegistrationUpdated(address,bool)"));
        assertEq(address(uint160(uint256(logs[0].topics[1]))), address(filterer2));
        assertEq(logs[1].topics[0], keccak256("OwnershipTransferred(address,address)"));
    }

    function testConstructor_copy() public {
        address deployed = computeCreateAddress(address(this), vm.getNonce(address(this)));
        vm.expectEmit(true, false, false, false, address(registry));
        emit RegistrationUpdated(deployed, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit OperatorUpdated(deployed, filteredAddress, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit CodeHashUpdated(deployed, filteredCodeHash, true);
        new ConcreteUpdatableOperatorFilterer(address(registry), address(filterer), false);
    }

    function testConstructor_subscribe() public {
        address deployed = computeCreateAddress(address(this), vm.getNonce(address(this)));
        vm.expectEmit(true, false, false, false, address(registry));
        emit RegistrationUpdated(deployed, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(deployed, address(filterer), true);
        vm.recordLogs();
        new ConcreteUpdatableOperatorFilterer(address(registry), address(filterer), true);
        assertEq(vm.getRecordedLogs().length, 2);
    }

    function testRegistryNotDeployedDoesNotRevert() public {
        vm.etch(address(registry), "");
        UpdatableFilterer filterer2 = new UpdatableFilterer(address(registry));
        assertTrue(filterer2.testFilter(notFiltered));
    }

    function testUpdateRegistry() public {
        address newRegistry = makeAddr("new registry");
        filterer.updateOperatorFilterRegistryAddress(newRegistry);
        assertEq(address(filterer.operatorFilterRegistry()), newRegistry);
    }

    function testUpdateRegistry_onlyOwner() public {
        vm.startPrank(makeAddr("notOwner"));
        vm.expectRevert(abi.encodeWithSignature("OnlyOwner()"));
        filterer.updateOperatorFilterRegistryAddress(address(0));
    }

    function testZeroAddressBypass() public {
        filterer.updateOperatorFilterRegistryAddress(address(0));
        vm.prank(filteredAddress);
        assertTrue(filterer.testFilter(address(0)));

        // can update even if registry is zero address
        filterer.updateOperatorFilterRegistryAddress(address(registry));
        vm.startPrank(filteredAddress);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        filterer.testFilter(address(0));
    }
}
