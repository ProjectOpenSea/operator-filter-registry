// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer721} from "../../src/example/OperatorFilterer721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract Filterer721 is OperatorFilterer721, Ownable {
    constructor() OperatorFilterer721(address(0), false) {}

    function testFilter(address from) public onlyAllowedOperator(from) returns (bool) {
        return true;
    }
}
