// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";

import {UpdatableOperatorFiltererUpgradeable} from
    "../../upgradeable/UpdatableOperatorFiltererUpgradeable.sol";

/**
 * @title  UpdatableExampleERC721Upgradeable
 * @author qed.team, abarbatei, balajmarius
 * @notice This example contract is configured to use the UpdatableOperatorFiltererUpgradeable, which registers the
 *         token and subscribes it to a give register filter.
 *         Adding the onlyAllowedOperator modifier to the setApprovalForAll, approve, transferFrom, safeTransferFrom (both version) methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry.
 */
abstract contract UpdatableExampleERC721Upgradeable is
    ERC721Upgradeable,
    UpdatableOperatorFiltererUpgradeable,
    OwnableUpgradeable
{
    function initialize(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe) public initializer {
        __ERC721_init("Example", "EXAMPLE");
        __Ownable_init();
        __UpdatableOperatorFiltererUpgradeable_init(_registry, subscriptionOrRegistrantToCopy, subscribe);
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

    function owner()
        public
        view
        virtual
        override (OwnableUpgradeable, UpdatableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }
}
