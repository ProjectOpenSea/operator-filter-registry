// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer721} from "../../src/example/OperatorFilterer721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract Filterer721 is OperatorFilterer721, Ownable {
    mapping(address => uint256) public balances;

    constructor() OperatorFilterer721(address(0), false) {}

    function testFilter(address from) public onlyAllowedOperator(from) returns (bool) {
        return true;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return balances[owner];
    }

    function setBalanceOf(address owner, uint256 amount) public {
        balances[owner] = amount;
    }
}
