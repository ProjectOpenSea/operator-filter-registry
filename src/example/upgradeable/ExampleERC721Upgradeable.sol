// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "openzeppelin-contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "../../upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/**
 * @title  ExampleERC721Upgradeable
 * @notice This example contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters.
 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry.
 */
abstract contract ExampleERC721Upgradeable is
    ERC721Upgradeable,
    ERC2981Upgradeable,
    DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable
{
    function initialize() public initializer {
        __ERC721_init("Example", "EXAMPLE");
        __ERC2981_init();
        __Ownable_init();
        __DefaultOperatorFilterer_init();
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
