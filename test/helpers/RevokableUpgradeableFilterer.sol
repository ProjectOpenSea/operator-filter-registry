// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableOperatorFiltererUpgradeable} from "../../src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract RevokableUpgradeableFilterer is RevokableOperatorFiltererUpgradeable, Ownable {
    constructor() RevokableOperatorFiltererUpgradeable() {}

    function testFilter(address from) public view onlyAllowedOperator(from) returns (bool) {
        return true;
    }

    function checkFilterOperator(address operator) public view {
        _checkFilterOperator(operator);
    }

    function init(address subscription, bool subscribe) public initializer {
        __OperatorFilterer_init(subscription, subscribe);
    }

    function owner() public view override (Ownable, RevokableOperatorFiltererUpgradeable) returns (address) {
        return Ownable.owner();
    }
}
