// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableOperatorFilterer} from "./RevokableOperatorFilterer.sol";

/**
 * @title  RevokableDefaultOperatorFilterer
 * @notice Inherits from RevokableOperatorFilterer and automatically subscribes to the default OpenSea subscription.
 *         Note that OpenSea will disable creator earnings enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 */
abstract contract RevokableDefaultOperatorFilterer is RevokableOperatorFilterer {
    /// @dev The default OpenSea subscription address
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor() RevokableOperatorFilterer(0x000000000000AAeB6D7670E522A718067333cd4E, DEFAULT_SUBSCRIPTION, true) {}
}
