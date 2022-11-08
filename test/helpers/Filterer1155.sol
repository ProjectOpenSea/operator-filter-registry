// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer1155} from "../../src/example/OperatorFilterer1155.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract Filterer1155 is OperatorFilterer1155, Ownable {
    constructor() OperatorFilterer1155(address(0), false) {}

    function testFilter(address from, uint256 id) public view onlyAllowedOperator(from, id) returns (bool) {
        return true;
    }
}
