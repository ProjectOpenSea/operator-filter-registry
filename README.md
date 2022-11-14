# Operator Filter Registry

This repository contains a number of tools to help token contracts manage the operators allowed to transfer tokens on behalf of users - including the smart contracts and delegates of marketplaces that do not respect creator fees.

This is not a foolproof approach - but it makes bypassing creator fees less liquid and easy at scale.

## How it works

Token smart contracts may register themselves (or be registered by their "owner") with the `OperatorFilterRegistry`. Token contracts or their "owner"s may then curate lists of operators (specific account addresses) and codehashes (smart contracts deployed with the same code) that should not be allowed to transfer tokens on behalf of users. 

## Creator Fee Enforcement

OpenSea will enforce creator fees for smart contracts that make best efforts to filter transfers from operators known to not respect creator fees.

This repository facilitates that process by providing smart contracts that interface with the registry automatically, including automatically subscribing to OpenSea's list of filtered operators. 

When filtering operators, use of this registry is not required, nor is it required for a token contract to "subscribe" to OpenSea's list within this registry. Subscriptions can be changed or removed at any time. Filtered operators and codehashes may likewise be added or removed at any time.

Contract owners may implement their own filtering outside of this registry, or they may use this registry to curate their own lists of filtered operators. However, there are certain contracts that are filtered by the default subscription, and must be filtered in order to be eligible for creator fee enforcement on OpenSea. 


## Filtered addresses

Entries in this list are added according to the following criteria:
* If the application most commonly used to interface with the contract gives buyers and sellers the ability to bypass creator fees when a similar transaction for the same item would require creator fee payment on OpenSea.io
* If the contract is facilitating the evasion of on-chain creator fee enforcement measures. For example, the contract uses a wrapper contact to bypass fee enforcement.

<table>
<tr>
<th>Name</th>
<th>Address</th>
<th>Network</th>
</tr>

<tr>
<td>LooksRare TransferManagerERC721</td>
<td>0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>LooksRare TransferManagerERC1155</td>
<td>0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>X2Y2 ERC721Delegate</td>
<td>0xf849de01b080adc3a814fabe1e2087475cf2e354</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>X2Y2 ERC1155Delegate</td>
<td>0x024ac22acdb367a3ae52a3d94ac6649fdc1f0779</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>SudoSwap LSSVMPairRouter</td>
<td>0x2b2e8cda09bba9660dca5cb6233787738ad68329</td>
<td>Ethereum Mainnet</td>
</tr>

</table>

## Deployments


<table>
<tr>
<th>Network</th>
<th>OperatorFilterRegistry</th>
<th>OpenSea Curated Subscription Address</th>
</tr>

<tr><td>Ethereum</td><td rowspan="14">

[0x000000000000AAeB6D7670E522A718067333cd4E](https://etherscan.io/address/0x000000000000AAeB6D7670E522A718067333cd4E#code)

</td><td rowspan="14">

0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6

</td></tr>

<tr><td>Goerli</td></tr>
</table>

## Usage

Token contracts that wish to manage lists of filtered operators and restrict transfers from them may integrate with the registry easily with tokens using the [`OperatorFilterer`](src/OperatorFilterer.sol) and [`DefaultOperatorFilterer`](src/DefaultOperatorFilterer.sol) contracts. These contracts provide a modifier (`isAllowedOperator`) which can be used on the token's transfer methods to restrict transfers from filtered operators.

See the [ExampleERC721](src/example/ExampleERC721.sol) and [ExampleERC1155](src/example/ExampleERC1155.sol) contracts for basic implementations that inherit the `DefaultOperatorFilterer`.


# Smart Contracts
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
- `address subscriptionOrRegistrantToCopy`: the address of the registrant the contract will either subscribe to, or do a one-time copy of that registrant's filters. If the zero address is provided, no subscription or copies will be made.
- `bool subscribe`: if true, subscribes to the previous address if it was not the zero address. If false, copies existing filtered addresses and codeHashes without subscribing to future updates.

### `onlyAllowedOperator(address operator)`
This modifier will revert if the `operator` or its code hash is filtered by the `OperatorFilterRegistry` contract.
## `DefaultOperatorFilterer`

This smart contract extends `OperatorFilterer` and automatically configures the token contract that inherits it to subscribe to OpenSea's list of filtered operators and code hashes. This subscription can be updated at any time by the owner by calling `updateSubscription` on the `OperatorFilterRegistry` contract.

## `OwnedRegistrant`

This `Ownable` smart contract is meant as a simple utility to enable subscription addresses that can easily be transferred to a new owner for administration. For example: an EOA curates a list of filtered operators and code hashes, and then transfers ownership of the `OwnedRegistrant` to a multisig wallet. 

# License

[MIT](LICENSE) Copyright 2022 Ozone Networks, Inc.
