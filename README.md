# Operator Filter Registry

This repository contains a number of tools to help token contracts manage the operators allowed to transfer tokens on the behalf of users - including the smart contracts and delegates of marketplaces that do not respect creator royalties.

This is not a foolproof approach - but it makes it especially difficult to bypass royalties at scale.


## `OperatorFilterRegistry`

`OperatorFilterRegistry` lets a smart contract or its [EIP-173 `Owner`](https://eips.ethereum.org/EIPS/eip-173) register a list of addresses and code hashes to deny when `isOperatorBlocked` is called.

It also supports "subscriptions," which allow a contract to delegate its operator filtering to another contract. This is useful for contracts that want to allow users to delegate their operator filtering to a trusted third party, who can continuously update the list of filtered operators and code hashes. Subscriptions may be cancelled at any time by the subscriber or its `Owner`.


### updateOperatorAddress(address registrant, address operator, bool filter)
This method will toggle filtering for an operator for a given registrant. If `filter` is `true`,  `isOperatorAllowed` will return `false`. If `filter` is `false`, `isOperatorAllowed` will return `true`. This can filter known addresses.

### updateOperatorCodeHash(address registrant, bytes32 codeHash, bool filter)
This method will toggle filtering on code hashes of operators given registrant. If an operator's `EXTCODEHASH` matches a filtered code hash, `isOperatorAllowed` will return `true`. Otherwise, `isOperatorAllowed` will return `false`. This can filter smart contract operators with different addresess but the same code.


## `OperatorFilterer`

This smart contract is meant to be inherited by token contracts so they can use the `onlyAllowedOperator` modifier on the `transferFrom` and `safeTransferFrom` methods.

On construction, it takes three parameters:
- `address registry`: the address of the `OperatorFilterRegistry` contract
- `address subscriptionOrRegistrantToCopy`: the address of the registrant the contract will either subscribe to, or do a one-time copy of that registrant's filters
- `bool subscribe`: if true, subscribes to the previous address. If false, copies existing filtered addresses and codeHashes without subscribing to future updates.

### `onlyAllowedOperator(address operator)`
This modifier will revert if the `operator` or its code hash is filtered by the `OperatorFilterRegistry` contract.
## `DefaultOperatorFilterer`

This smart contract extends `OperatorFilterer` and automatically configures the token contract that inherits it to subscribe to OpenSea's list of filtered operators and code hashes. This subscription can be updated at any time by the owner by calling `updateSubscription` on the `OperatorFilterRegistry` contract.

## `OwnedRegistrant`

This `Ownable` smart contract is meant as a simple utility to enable subscription addresses that can easily be transferred to a new owner for administration. For example: an EOA curates a list of filtered operators and code hashes, and then transfers ownership of the `OwnedRegistrant` to a multisig wallet. 