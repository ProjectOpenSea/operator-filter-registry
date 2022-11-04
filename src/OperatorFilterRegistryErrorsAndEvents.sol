// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract OperatorFilterRegistryErrorsAndEvents {
    error CannotFilterZeroCodeHash();
    error AddressAlreadyFiltered(address operator);
    error AddressNotFiltered(address operator);
    error CodeHashAlreadyFiltered(bytes32 codeHash);
    error CodeHashNotFiltered(bytes32 codeHash);
    error OnlyAddressOrOwner();
    error NotRegistered(address registrant);
    error AlreadyRegistered();
    error AlreadySubscribed(address subscription);
    error NotSubscribed();
    error CannotUpdateWhileSubscribed(address subscription);
    error CannotSubscribeToSelf();
    error CannotSubscribeToZeroAddress();
    error NotOwnable();
    error AddressFiltered(address filtered);
    error CodeHashFiltered(address account, bytes32 codeHash);
    error CannotSubscribeToRegistrantWithSubscription(address registrant);

    event RegistrationUpdated(address indexed addr, bool indexed registered);
    event OperatorUpdated(address indexed addr, address indexed operator, bool filtered);
    event CodeHashUpdated(address indexed addr, bytes32 indexed codeHash, bool filtered);
    event SubscriptionUpdated(address indexed addr, address indexed registrant, bool indexed subscribed);
}
