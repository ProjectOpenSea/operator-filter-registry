// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";
import {IOperatorFilterRegistry} from "../IOperatorFilterRegistry.sol";

/**
 * @title  Upgradeable storage layout for UpdatableOperatorFiltererUpgradeable.
 * @author qed.team, abarbatei, balajmarius
 * @notice Upgradeable contracts must use a storage layout that can be used across upgrades.
 *         Only append new variables to the end of the layout.
 */
library UpdatableOperatorFiltererUpgradeableStorage {
    struct Layout {
        /// @dev Address of the opensea filter register contract
        address _operatorFilterRegistry;
    }

    /// @dev The EIP-1967 specific storage slot for the layout
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(bytes("UpdatableOperatorFiltererUpgradeable.contracts.storage"))) - 1);

    /// @dev The layout of the storage.
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/**
 * @title  UpdatableOperatorFiltererUpgradeable
 * @author qed.team, abarbatei, balajmarius
 * @notice Abstract contract whose init function automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry. This contract allows the Owner to update the
 *         OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero address,
 *         which will bypass registry checks.
 *         Note that OpenSea will still disable creator earnings enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Use updateOperatorFilterRegistryAddress function to change registry address if needed
 */
abstract contract UpdatableOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    using UpdatableOperatorFiltererUpgradeableStorage for UpdatableOperatorFiltererUpgradeableStorage.Layout;

    /// @notice Emitted when someone other than the owner is trying to call an only owner function.
    error OnlyOwner();

    /// @notice Emitted when the operator filter registry address is changed by the owner of the contract
    event OperatorFilterRegistryAddressUpdated(address newRegistry);

    /**
     * @notice Initialization function in accordance with the upgradable pattern
     * @dev The upgradeable initialize function specific to proxied contracts
     * @param _registry Registry address to which to register to for blocking operators that do not respect royalties
     * @param subscriptionOrRegistrantToCopy Subscription address to use as a template for when
     *                                       imitating/copying blocked addresses and codehashes
     * @param subscribe If to subscribe to the subscriptionOrRegistrantToCopy address or just copy entries from it
     */
    function __UpdatableOperatorFiltererUpgradeable_init(
        address _registry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal onlyInitializing {
        UpdatableOperatorFiltererUpgradeableStorage.layout()._operatorFilterRegistry = _registry;
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(_registry);
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(registry).code.length > 0) {
            if (subscribe) {
                registry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    registry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    registry.register(address(this));
                }
            }
        }
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     * @custom:event OperatorFilterRegistryAddressUpdated
     * @param newRegistry The address of the registry that will be used for this contract
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public virtual {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        UpdatableOperatorFiltererUpgradeableStorage.layout()._operatorFilterRegistry = newRegistry;
        emit OperatorFilterRegistryAddressUpdated(newRegistry);
    }

    /**
     * @dev Helper function to return the value of the currently used registry address
     */
    function operatorFilterRegistry() public view returns (address) {
        return address(UpdatableOperatorFiltererUpgradeableStorage.layout()._operatorFilterRegistry);
    }

    /**
     * @dev Assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);

    /**
     * @dev A helper function to check if the operator is allowed
     */
    function _checkFilterOperator(address operator) internal view virtual override {
        IOperatorFilterRegistry registry =
            IOperatorFilterRegistry(UpdatableOperatorFiltererUpgradeableStorage.layout()._operatorFilterRegistry);
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting or
            // upgraded contracts may specify their own OperatorFilterRegistry implementations, which may behave
            // differently
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}
