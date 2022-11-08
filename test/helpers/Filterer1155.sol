// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer1155} from "../../src/OperatorFilterer1155.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract Filterer1155 is OperatorFilterer1155, Ownable {
    mapping(address => mapping(uint256 => uint256)) public balances;

    constructor() OperatorFilterer1155(address(0), false) {}

    function testFilter(address from, uint256 id) public onlyAllowedOperator(from, id) returns (bool) {
        return true;
    }

    function balanceOf(address owner, uint256 id) public view virtual override returns (uint256) {
        return balances[owner][id];
    }

    function setBalanceOf(address owner, uint256 id, uint256 amount) public {
        balances[owner][id] = amount;
    }
}
