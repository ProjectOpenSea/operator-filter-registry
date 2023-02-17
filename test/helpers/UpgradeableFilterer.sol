// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "../../src/upgradeable/OperatorFiltererUpgradeable.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract UpgradeableFilterer is OperatorFiltererUpgradeable, Ownable {
    constructor() OperatorFiltererUpgradeable() {}

    function testFilter(address from) public view onlyAllowedOperator(from) returns (bool) {
        return true;
    }

    function checkFilterOperator(address operator) public view {
        _checkFilterOperator(operator);
    }

    function init(address subscription, bool subscribe) public initializer {
        __OperatorFilterer_init(subscription, subscribe);
    }
}
