// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer721} from "../src/example/OperatorFilterer721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {BaseRegistryTest} from "./BaseRegistryTest.sol";
import {Vm} from "forge-std/Vm.sol";
import {OperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents} from "../src/OperatorFilterRegistry.sol";
import {Filterer721} from "./helpers/Filterer721.sol";

contract ConcreteOperatorFilterer721 is OperatorFilterer721 {
    constructor(address registrant, bool sub) OperatorFilterer721(registrant, sub) {}
}

contract OperatorFilterer721Test is BaseRegistryTest {
    Filterer721 filterer;
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;
    address notFiltered;

    function setUp() public override {
        super.setUp();
        notFiltered = makeAddr("not filtered");
        filterer = new Filterer721();
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
        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, filteredAddress));
        filterer.testFilter(filteredAddress);
        vm.expectRevert(abi.encodeWithSelector(CodeHashFiltered.selector, filteredCodeHashAddress, filteredCodeHash));
        filterer.testFilter(filteredCodeHashAddress);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function testConstructory_noSubscribeOrCopy() public {
        vm.recordLogs();
        Filterer721 filterer2 = new Filterer721();
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
        new ConcreteOperatorFilterer721(address(filterer), false);
    }

    function testConstructor_subscribe() public {
        address deployed = computeCreateAddress(address(this), vm.getNonce(address(this)));
        vm.expectEmit(true, false, false, false, address(registry));
        emit RegistrationUpdated(deployed, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(deployed, address(filterer), true);
        vm.recordLogs();
        new ConcreteOperatorFilterer721(address(filterer), true);
        assertEq(vm.getRecordedLogs().length, 2);
    }

    function testRegistryNotDeployedDoesNotRevert() public {
        vm.etch(address(registry), "");
        Filterer721 filterer2 = new Filterer721();
        assertTrue(filterer2.testFilter(notFiltered));
    }
}
