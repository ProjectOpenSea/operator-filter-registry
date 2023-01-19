// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableOperatorFiltererUpgradeable} from "./RevokableOperatorFiltererUpgradeable.sol";

/**
 * @title  RevokableDefaultOperatorFiltererUpgradeable
 * @notice Inherits from RevokableOperatorFiltererUpgradeable and automatically subscribes to the default OpenSea subscription
 *         when the init function is called.
 *         Note that OpenSea will disable creator earnings enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 */
abstract contract RevokableDefaultOperatorFiltererUpgradeable is RevokableOperatorFiltererUpgradeable {
    /// @dev The default OpenSea subscription address
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    /// @dev The upgradeable initialize function that should be called when the contract is being upgraded.
    function __RevokableDefaultOperatorFilterer_init() internal onlyInitializing {
        RevokableOperatorFiltererUpgradeable.__RevokableOperatorFilterer_init(DEFAULT_SUBSCRIPTION, true);
    }
}
