// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UpdateableOperatorFilterer} from "./UpdateableOperatorFilterer.sol";

/**
 * @title  RevokableOperatorFilterer
 * @notice This contract is meant to allow contracts to permanently skip OperatorFilterRegistry checks if desired. The
 *         Registry itself has an "unregister" function, but if the contract is ownable, the owner can re-register at
 *         any point. As implemented, this abstract contract allows the contract owner to permanently skip the
 *         OperatorFilterRegistry checks by passing the zero address to updateRegistryAddress. Once done, the registry
 *         address cannot be further updated.
 */
abstract contract RevokableOperatorFilterer is UpdateableOperatorFilterer {
    error RegistryHasBeenRevoked();
    error RegistryAddressCannotBeZeroAddress();

    constructor(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe)
        UpdateableOperatorFilterer(_registry, subscriptionOrRegistrantToCopy, subscribe)
    {
        // don't allow creating a contract with a permanently revoked registry
        if (_registry == address(0)) {
            revert RegistryAddressCannotBeZeroAddress();
        }
    }

    function _checkFilterOperator(address operator) internal view virtual override {
        if (address(operatorFilterRegistry) != address(0)) {
            super._checkFilterOperator(operator);
        }
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be permanently bypassed, and the address cannot be updated again. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public override {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        // if registry address has been set to 0 (revoked), do not allow further updates
        if (address(operatorFilterRegistry) == address(0)) {
            revert RegistryHasBeenRevoked();
        }
        super.updateOperatorFilterRegistryAddress(newRegistry);
    }

    function isOperatorFilterRegistryRevoked() public view returns (bool) {
        return address(operatorFilterRegistry) == address(0);
    }
}
