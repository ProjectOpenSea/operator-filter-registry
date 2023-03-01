// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Vm.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";

import {UpdatableExampleERC721Upgradeable} from 
    "../../../src/example/upgradeable/UpdatableExampleERC721Upgradeable.sol";
import {UpdatableOperatorFiltererUpgradeable} from
    "../../../src/upgradeable/UpdatableOperatorFiltererUpgradeable.sol";
import {BaseRegistryTest} from "../../BaseRegistryTest.sol";

import {OperatorFilterRegistryStub} from "../../helpers/OperatorFilterRegistryStub.sol";

import {OperatorFilterer} from "../../../src/OperatorFilterer.sol";

contract TestableUpdatableExampleERC721Upgradeable is UpdatableExampleERC721Upgradeable {
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract UpdatableERC721UpgradeableForUpgradableTest is BaseRegistryTest, Initializable {
    TestableUpdatableExampleERC721Upgradeable example;
    address filteredAddress;
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function setUp() public override {
        super.setUp();

        vm.startPrank(DEFAULT_SUBSCRIPTION);
        registry.register(DEFAULT_SUBSCRIPTION);
        
        filteredAddress = makeAddr("filtered address");
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), filteredAddress, true);
        vm.stopPrank();

        example = new TestableUpdatableExampleERC721Upgradeable();
        example.initialize(address(registry), DEFAULT_SUBSCRIPTION, true);
    }

    function testUpgradeable() public {
        TestableUpdatableExampleERC721Upgradeable example2 = new TestableUpdatableExampleERC721Upgradeable();
        vm.expectEmit(true, true, false, true, address(example2));
        emit Initialized(1);
        example2.initialize(address(registry), DEFAULT_SUBSCRIPTION, true);
        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        example2.initialize(address(registry), DEFAULT_SUBSCRIPTION, true);
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

    function testOwnersNotExcluded() public {
        address alice = address(0xA11CE);
        example.mint(alice, 1);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.prank(alice);
        example.transferFrom(alice, makeAddr("to"), 1);
    }

    function testOwnersNotExcludedSafeTransfer() public {
        address alice = address(0xA11CE);
        example.mint(alice, 1);
        example.mint(alice, 2);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(address(DEFAULT_SUBSCRIPTION), alice, true);

        vm.startPrank(alice);
        example.safeTransferFrom(alice, makeAddr("to"), 1);
        example.safeTransferFrom(alice, makeAddr("to"), 2, "");
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
        example.transferFrom(bob, makeAddr("to"), 1);
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

        vm.expectRevert(abi.encodeWithSelector(AddressFiltered.selector, alice));
        example.approve(alice, 1);
    }
}


contract ConcreteUpdatableOperatorFiltererUpgradable is UpdatableOperatorFiltererUpgradeable, OwnableUpgradeable {
    
    function initialize(address registry, address registrant, bool sub) public initializer {
        __Ownable_init();
        __UpdatableOperatorFiltererUpgradeable_init(registry, registrant, sub);
    }

    function testFilter(address from) public view onlyAllowedOperator(from) returns (bool) {
        return true;
    }

    function checkFilterOperator(address operator) public view {
        _checkFilterOperator(operator);
    }

    function owner()
        public
        view
        virtual
        override (OwnableUpgradeable, UpdatableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }
}

contract UpdatableERC721UpgradeableForUpdatableTest is BaseRegistryTest {
    ConcreteUpdatableOperatorFiltererUpgradable filterer;
    address filteredAddress;
    address filteredCodeHashAddress;
    bytes32 filteredCodeHash;
    address notFiltered;

    function setUp() public override {
        super.setUp();
        notFiltered = makeAddr("not filtered");
        filterer = new ConcreteUpdatableOperatorFiltererUpgradable();
        filterer.initialize(address(registry), address(0), false);
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
        ConcreteUpdatableOperatorFiltererUpgradable filterer2 = new ConcreteUpdatableOperatorFiltererUpgradable();
        filterer2.initialize(address(registry), address(0), false);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 3);
        assertEq(logs[0].topics[0], keccak256("OwnershipTransferred(address,address)"));
        assertEq(logs[1].topics[0], keccak256("RegistrationUpdated(address,bool)"));
        assertEq(address(uint160(uint256(logs[1].topics[1]))), address(filterer2));
        assertEq(logs[2].topics[0], keccak256("Initialized(uint8)"));
        
    }

    function testConstructor_copy() public {
        address deployed = computeCreateAddress(address(this), vm.getNonce(address(this)));
        vm.expectEmit(true, false, false, false, address(registry));
        emit RegistrationUpdated(deployed, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit OperatorUpdated(deployed, filteredAddress, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit CodeHashUpdated(deployed, filteredCodeHash, true);

        vm.recordLogs();
        ConcreteUpdatableOperatorFiltererUpgradable filterer2 = new ConcreteUpdatableOperatorFiltererUpgradable();
        filterer2.initialize(address(registry), address(filterer), false);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 5);
        assertEq(logs[0].topics[0], keccak256("OwnershipTransferred(address,address)"));
        assertEq(logs[1].topics[0], keccak256("RegistrationUpdated(address,bool)"));
        assertEq(address(uint160(uint256(logs[1].topics[1]))), address(filterer2));
        assertEq(logs[2].topics[0], keccak256("OperatorUpdated(address,address,bool)"));
        assertEq(address(uint160(uint256(logs[2].topics[1]))), address(filterer2));
        assertEq(logs[3].topics[0], keccak256("CodeHashUpdated(address,bytes32,bool)"));
        assertEq(address(uint160(uint256(logs[3].topics[1]))), address(filterer2));
        assertEq(logs[4].topics[0], keccak256("Initialized(uint8)"));
    }

    function testConstructor_subscribe() public {
        address deployed = computeCreateAddress(address(this), vm.getNonce(address(this)));
        vm.expectEmit(true, false, false, false, address(registry));
        emit RegistrationUpdated(deployed, true);
        vm.expectEmit(true, true, true, false, address(registry));
        emit SubscriptionUpdated(deployed, address(filterer), true);
        
        vm.recordLogs();
        ConcreteUpdatableOperatorFiltererUpgradable filterer2 = new ConcreteUpdatableOperatorFiltererUpgradable();
        filterer2.initialize(address(registry), address(filterer), true);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 4);
        assertEq(logs[0].topics[0], keccak256("OwnershipTransferred(address,address)"));
        assertEq(logs[1].topics[0], keccak256("RegistrationUpdated(address,bool)"));
        assertEq(address(uint160(uint256(logs[1].topics[1]))), address(filterer2));
        assertEq(logs[2].topics[0], keccak256("SubscriptionUpdated(address,address,bool)"));
        assertEq(address(uint160(uint256(logs[2].topics[1]))), address(filterer2));
        assertEq(logs[3].topics[0], keccak256("Initialized(uint8)"));
    }

    function testRegistryNotDeployedDoesNotRevert() public {
        vm.etch(address(registry), "");
        ConcreteUpdatableOperatorFiltererUpgradable filterer2 = new ConcreteUpdatableOperatorFiltererUpgradable();
        filterer2.initialize(address(registry), address(0), false);
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

    function testRevert_OperatorNotAllowed() public {
        address stubRegistry = address(new OperatorFilterRegistryStub());
        ConcreteUpdatableOperatorFiltererUpgradable updatableFilterer = new ConcreteUpdatableOperatorFiltererUpgradable();
        updatableFilterer.initialize(stubRegistry, address(0), false);
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterer.OperatorNotAllowed.selector, address(filteredAddress)));
        updatableFilterer.checkFilterOperator(filteredAddress);
    }
}
