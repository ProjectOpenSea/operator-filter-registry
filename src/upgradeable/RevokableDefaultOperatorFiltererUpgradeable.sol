// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableOperatorFiltererUpgradeable} from "./RevokableOperatorFiltererUpgradeable.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "../lib/Constants.sol";

abstract contract RevokableDefaultOperatorFiltererUpgradeable is RevokableOperatorFiltererUpgradeable {
    function __RevokableDefaultOperatorFilterer_init() internal onlyInitializing {
        RevokableOperatorFiltererUpgradeable.__RevokableOperatorFilterer_init(CANONICAL_CORI_SUBSCRIPTION, true);
    }
}
