// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableOperatorFilterer} from "./RevokableOperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  RevokableDefaultOperatorFilterer
 * @notice Inherits from RevokableOperatorFilterer and automatically subscribes to the default OpenSea subscription.
 *         Note that OpenSea will disable creator fee enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 */

abstract contract RevokableDefaultOperatorFilterer is RevokableOperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(CANONICAL_CORI_SUBSCRIPTION);

    constructor() RevokableOperatorFilterer(0x000000000000AAeB6D7670E522A718067333cd4E, DEFAULT_SUBSCRIPTION, true) {}
}
