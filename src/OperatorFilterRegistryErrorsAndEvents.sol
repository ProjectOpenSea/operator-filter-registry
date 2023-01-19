// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract OperatorFilterRegistryErrorsAndEvents {
    /// @notice Emitted when trying to register an address that has no code.
    error CannotFilterEOAs();

    /// @notice Emitted when trying to add an address that is already filtered.
    error AddressAlreadyFiltered(address operator);

    /// @notice Emitted when trying to remove an address that is not filtered.
    error AddressNotFiltered(address operator);

    /// @notice Emitted when trying to add a codehash that is already filtered.
    error CodeHashAlreadyFiltered(bytes32 codeHash);

    /// @notice Emitted when trying to remove a codehash that is not filtered.
    error CodeHashNotFiltered(bytes32 codeHash);

    /// @notice Emitted when the caller is not the address or EIP-173 "owner()"
    error OnlyAddressOrOwner();

    /// @notice Emitted when the registrant is not registered.
    error NotRegistered(address registrant);

    /// @notice Emitted when the registrant is already registered.
    error AlreadyRegistered();

    /// @notice Emitted when the registrant is already subscribed.
    error AlreadySubscribed(address subscription);

    /// @notice Emitted when the registrant is not subscribed.
    error NotSubscribed();

    /// @notice Emitted when trying to update a registration where the registrant is already subscribed.
    error CannotUpdateWhileSubscribed(address subscription);

    /// @notice Emitted when trying to subscribe to itself.
    error CannotSubscribeToSelf();

    /// @notice Emitted when trying to subscribe to the zero address.
    error CannotSubscribeToZeroAddress();

    /// @notice Emitted when trying to register and the contract is not ownable (EIP-173 "owner()")
    error NotOwnable();

    /// @notice Emitted when an address is filtered.
    error AddressFiltered(address filtered);

    /// @notice Emitted when a codeHash is filtered.
    error CodeHashFiltered(address account, bytes32 codeHash);

    /// @notice Emited when trying to register to a registrant with a subscription.
    error CannotSubscribeToRegistrantWithSubscription(address registrant);

    /// @notice Emitted when trying to copy a registration from itself.
    error CannotCopyFromSelf();

    /// @notice Emitted when a registration is updated.
    event RegistrationUpdated(address indexed registrant, bool indexed registered);

    /// @notice Emitted when an operator is updated.
    event OperatorUpdated(address indexed registrant, address indexed operator, bool indexed filtered);

    /// @notice Emitted when multiple operators are updated.
    event OperatorsUpdated(address indexed registrant, address[] operators, bool indexed filtered);

    /// @notice Emitted when a codeHash is updated.
    event CodeHashUpdated(address indexed registrant, bytes32 indexed codeHash, bool indexed filtered);

    /// @notice Emitted when multiple codeHashes are updated.
    event CodeHashesUpdated(address indexed registrant, bytes32[] codeHashes, bool indexed filtered);

    /// @notice Emitted when a subscription is updated.
    event SubscriptionUpdated(address indexed registrant, address indexed subscription, bool indexed subscribed);
}
