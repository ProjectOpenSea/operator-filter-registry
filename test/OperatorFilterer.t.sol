// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "../src/OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {OperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents} from "../src/OperatorFilterRegistry.sol";

contract Filterer is OperatorFilterer, Ownable {
    constructor(address registry) OperatorFilterer(registry, address(0), false) {}

    function testFilter() public onlyAllowedOperator returns (bool) {
        return true;
    }
}

contract OperatorFiltererTest is Test, OperatorFilterRegistryErrorsAndEvents {
    Filterer filterer;
    OperatorFilterRegistry registry;
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;

    function setUp() public {
        registry = new OperatorFilterRegistry();

        filterer = new Filterer(address(registry));
        // registry.register(address(filterer));
        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(filterer), filteredAddress, true);
        filteredCodeHashAddress = makeAddr("filtered code hash");
        bytes memory code = hex"deadbeef";
        filteredCodeHash = keccak256(code);
        registry.updateCodeHash(address(filterer), filteredCodeHash, true);
        vm.etch(filteredCodeHashAddress, code);
    }

    function testFilter() public {
        assertTrue(filterer.testFilter());
        vm.startPrank(filteredAddress);
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        filterer.testFilter();
        vm.stopPrank();
        vm.startPrank(filteredCodeHashAddress);
        vm.expectRevert(abi.encodeWithSelector(CodeHashFiltered.selector, filteredCodeHashAddress, filteredCodeHash));
        filterer.testFilter();
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function testConstructory_noSubscribeOrCopy() public {
        vm.recordLogs();
        Filterer filterer2 = new Filterer(address(registry));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(logs.length, 2);
        assertEq(logs[0].topics[0], RegistrationUpdated.selector);
        assertEq(address(uint160(uint256(logs[0].topics[1]))), address(filterer2));
        assertEq(logs[1].topics[0], OwnershipTransferred.selector);
    }

    function testConstructor_copy() public {
        address deployed = computeCreateAddress(address(this), vm.getNonce(address(this)));
        vm.expectEmit(true, false, false, false, address(registry));
        emit RegistrationUpdated(deployed, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit OperatorUpdated(deployed, filteredAddress, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit CodeHashUpdated(deployed, filteredCodeHash, true);
        new OperatorFilterer(address(registry), address(filterer), false);
    }

    function testConstructor_subscribe() public {
        address deployed = computeCreateAddress(address(this), vm.getNonce(address(this)));
        vm.expectEmit(true, false, false, false, address(registry));
        emit RegistrationUpdated(deployed, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(deployed, address(filterer), true);
        vm.recordLogs();
        new OperatorFilterer(address(registry), address(filterer), true);
        assertEq(vm.getRecordedLogs().length, 2);
    }

    function testRegistryNotDeployedDoesNotRevert() public {
        Filterer filterer2 = new Filterer(makeAddr('no code'));
        assertTrue(filterer2.testFilter());
    }
}
