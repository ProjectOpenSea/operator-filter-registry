// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DefaultOperatorFilterer} from "../src/DefaultOperatorFilterer.sol";
import {OperatorFilterer} from "../src/OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Test} from "forge-std/Test.sol";
import {OperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents} from "../src/OperatorFilterRegistry.sol";

contract DefaultFilterer is DefaultOperatorFilterer, Ownable {
    constructor() DefaultOperatorFilterer() {}

    function filterTest(address addr) public onlyAllowedOperator(addr) returns (bool) {
        return true;
    }
}

contract DefaultOperatorFiltererTest is Test, OperatorFilterRegistryErrorsAndEvents {
    DefaultFilterer filterer;
    OperatorFilterRegistry registry;
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;
    address constant DEFAULT_OPERATOR_FILTER_REGISTRY = address(0xdeadbeef);
    address constant DEFAULT_SUBSCRIPTION = address(0xdadb0d);

    function setUp() public {
        vm.etch(DEFAULT_OPERATOR_FILTER_REGISTRY, address(new OperatorFilterRegistry()).code);
        registry = OperatorFilterRegistry(DEFAULT_OPERATOR_FILTER_REGISTRY);

        vm.startPrank(DEFAULT_SUBSCRIPTION);
        registry.register(DEFAULT_SUBSCRIPTION);

        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), filteredAddress, true);
        filteredCodeHashAddress = makeAddr("filtered code hash");
        bytes memory code = hex"deadbeef";
        filteredCodeHash = keccak256(code);
        registry.updateCodeHash(address(DEFAULT_SUBSCRIPTION), filteredCodeHash, true);
        vm.etch(filteredCodeHashAddress, code);

        filterer = new DefaultFilterer();
    }

    function testFilter() public {
        assertTrue(filterer.filterTest(address(this)));
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterer.OperatorNotAllowed.selector, filteredAddress));
        filterer.filterTest(filteredAddress);
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterer.OperatorNotAllowed.selector, filteredCodeHashAddress));
        filterer.filterTest(filteredCodeHashAddress);
    }
}
