// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ValidationTest} from "./Validation.t.sol";
import {TestableExampleERC721} from "../example/ExampleERC721.t.sol";

interface IOperatorFilterRegistry {
    function filteredOperators(address addr) external returns (address[] memory);
}

contract ExampleERC721ValidationTest is ValidationTest {
    function setUp() public override {
        owner = makeAddr("owner");
        tokenId = 1;

        // Fork mainnet
        vm.createSelectFork(stdChains["mainnet"].rpcUrl);
        filteredOperators =
            IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY).filteredOperators(CANONICAL_OPENSEA_REGISTRANT);
        TestableExampleERC721 nftContract = new TestableExampleERC721();
        nftContract.mint(owner, tokenId);
        contractAddress = address(nftContract);
    }
}
