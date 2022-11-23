// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";
import {TestableExampleERC721} from "../example/ExampleERC721.t.sol";

interface IOperatorFilterRegistry {
    function filteredOperators(address addr) external returns (address[] memory);
}

contract ValidationTest is Test {
    address constant CANONICAL_OPERATOR_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;
    address constant CANONICAL_OPENSEA_REGISTRANT = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    // Contract to test against
    address contractAddress;

    // Token ID to test against
    uint256 tokenId;

    // Owner of the NFT
    address owner;

    address[] filteredOperators;

    function setUp() public virtual {
        // Fork network
        try vm.envString("NETWORK_RPC_URL") returns (string memory envNetwork) {
            vm.createSelectFork(stdChains[envNetwork].rpcUrl);
        } catch {
            // fallback to mainnet
            vm.createSelectFork(stdChains["mainnet"].rpcUrl);
        }

        filteredOperators =
            IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY).filteredOperators(CANONICAL_OPENSEA_REGISTRANT);

        // try to load token ID from .env
        try vm.envUint("TOKEN_ID") returns (uint256 _tokenId) {
            tokenId = _tokenId;
        } catch (bytes memory) {
            // fallback to 1
            tokenId = 1;
        }

        // try to load owner from .env
        try vm.envAddress("OWNER") returns (address _owner) {
            owner = _owner;
        } catch (bytes memory) {
            // fallback to dummy EOA
            owner = makeAddr("owner");
        }

        // try to load contract address from .env
        try vm.envAddress("CONTRACT_ADDRESS") returns (address _contractAddress) {
            contractAddress = _contractAddress;
        } catch (bytes memory) {
            // fallback to deploying new contract
            TestableExampleERC721 nftContract = new TestableExampleERC721();
            nftContract.mint(owner, tokenId);
            contractAddress = address(nftContract);
        }
    }

    function testERC721() public {
        IERC721 nftContract = IERC721(contractAddress);

        // Try to get the current owner of the NFT, falling back to value set during setup on revert
        try nftContract.ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch (bytes memory) {
            // Do nothing
        }

        for (uint256 i = 0; i < filteredOperators.length; i++) {
            address operator = filteredOperators[i];

            // Try to set approval for the operator
            vm.startPrank(owner);
            try nftContract.setApprovalForAll(operator, true) {
                // blocking approvals is not required, so continue to check transfers
            } catch (bytes memory) {
                // continue to test transfer methods, since marketplace approvals can be
                // hard-coded into contracts
            }

            // also include per-token approvals as those may not be blocked
            try nftContract.approve(operator, tokenId) {
                // continue to check transfers
            } catch (bytes memory) {
                // continue to test transfer methods, since marketplace approvals can be
                // hard-coded into contracts
            }

            vm.stopPrank();
            // Ensure operator is not able to transfer the token
            vm.startPrank(operator);
            vm.expectRevert();
            nftContract.safeTransferFrom(owner, address(1), tokenId);

            vm.expectRevert();
            nftContract.safeTransferFrom(owner, address(1), tokenId, "");

            vm.expectRevert();
            nftContract.transferFrom(owner, address(1), tokenId);
            vm.stopPrank();
        }
    }

    function testERC1155() public {
        IERC1155 nftContract = IERC1155(contractAddress);
        for (uint256 i = 0; i < filteredOperators.length; i++) {
            address operator = filteredOperators[i];

            // Try to set approval for the operator
            vm.prank(owner);
            try nftContract.setApprovalForAll(operator, true) {}
            catch (bytes memory) {
                // even if approval reverts, continue to test transfer methods, since marketplace approvals can be
                // hard-coded into contracts
            }

            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = tokenId;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = 1;

            // Ensure operator is not able to transfer the token
            vm.startPrank(operator);
            vm.expectRevert();
            nftContract.safeTransferFrom(owner, address(1), tokenId, 1, "");

            vm.expectRevert();
            nftContract.safeBatchTransferFrom(owner, address(1), tokenIds, amounts, "");

            vm.stopPrank();
        }
    }
}
