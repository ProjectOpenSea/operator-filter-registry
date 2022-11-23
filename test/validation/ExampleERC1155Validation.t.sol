// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ValidationTest} from "./Validation.t.sol";
import {TestableExampleERC1155} from "../example/ExampleERC1155.t.sol";

interface IOperatorFilterRegistry {
    function filteredOperators(address addr) external returns (address[] memory);
}

contract ExampleERC1155ValidationTest is ValidationTest {
    function setUp() public override {
        owner = makeAddr("owner");
        tokenId = 1;

        // Fork mainnet
        vm.createSelectFork(stdChains["mainnet"].rpcUrl);
        filteredOperators =
            IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY).filteredOperators(CANONICAL_OPENSEA_REGISTRANT);
        TestableExampleERC1155 nftContract = new TestableExampleERC1155();
        nftContract.mint(owner, tokenId);
        contractAddress = address(nftContract);
    }
}
