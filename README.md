# Operator Filter Registry

This repository contains a number of tools to help token contracts manage the operators allowed to transfer tokens on behalf of users - including the smart contracts and delegates of marketplaces that do not respect creator fees.

This is not a foolproof approach - but it makes it difficult to bypass creator fees at scale.

## How it works

Token smart contracts may register themselves (or be registered by their "owner") with the `OperatorFilterRegistry`. Token contracts or their "owner"s may then curate lists of operators (specific account addresses) and codehashes (smart contracts deployed with the same code) that should not be allowed to transfer tokens on behalf of users. 

## Creator Fee Enforcement

OpenSea will enforce creator fees for smart contracts that make best efforts to filter transfers from operators known to not respect creator fees.

This repository facilitates that process by providing smart contracts that interface with the registry automatically, including automatically subscribing to OpenSea's list of filtered operators. 

When filtering operators, use of this registry is not required, nor is it required for a token contract to "subscribe" to OpenSea's list within this registry. Subscriptions can be changed or removed at any time. Filtered operators and codehashes may likewise be added or removed at any time.

Contract owners may implement their own filtering outside of this registry, or they may use this registry to curate their own lists of filtered operators. However, there are certain contracts that are filtered by the default subscription, and must be filtered in order to be eligible for creator fee enforcement on OpenSea. 


## Filtered addresses

Entries in this list are added according to specific criteria.

\<criteria goes here\>

<table>
<tr>
<th>Name</th>
<th>Address</th>
<th>Network</th>
</tr>

<tr>
<td>Blur.io ExecutionDelegate</td>
<td >
0x00000000000111AbE46ff893f3B2fdF1F759a8A8
</td>
<td >
Ethereum Mainnet
</td>
</tr>

<tr>
<td>LooksRareExchange</td>
<td>0x59728544b08ab483533076417fbbb2fd0b17ce3a</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>X2Y2 ERC721Delegate</td>
<td>0xf849de01b080adc3a814fabe1e2087475cf2e354</td>
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
<th>OpenSea Curated Subscription</th>
</tr>

<tr><td>Ethereum</td><td rowspan="14">

[0x80375A0344834520f3d0b2BAEA9ECb0A1b313188](https://etherscan.io/address/0x80375A0344834520f3d0b2BAEA9ECb0A1b313188#code)

</td><td rowspan="14">

[0x38DD5db8A74Ca1bd2059C19CAb8610ad25FC9Be0](https://etherscan.io/address/0x38DD5db8A74Ca1bd2059C19CAb8610ad25FC9Be0#code)

</td></tr>

<tr><td>Goerli</td></tr>
</table>

## Usage

Token contracts that wish to manage lists of filtered operators and restrict transfers from them may integrate with the registry easily using the [`OperatorFilterer`](src/OperatorFilterer.sol) and [`DefaultOperatorFilterer`](src/DefaultOperatorFilterer.sol) contracts. These contracts provide a modifier (`isAllowedOperator`) which can be used on the token's transfer methods to restrict transfers from filtered operators.

See the [ExampleERC721](src/example/ExampleERC721.sol) contract for a basic implementation that inherits the `DefaultOperatorFilterer`.


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