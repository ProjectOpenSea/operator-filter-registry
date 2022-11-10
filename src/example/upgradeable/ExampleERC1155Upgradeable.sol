// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC1155Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "../../upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title  ExampleERC1155Upgradeable
 * @notice This example contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters.
 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry.
 */
abstract contract ExampleERC1155Upgradeable is
    ERC1155Upgradeable,
    DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable
{
    function initialize() public initializer {
        __ERC1155_init(
            "ipfs://bafybeih2nhapbsjyic4ilfy35w7o5gwyk3wvhabwt2jfa4l3fqdq3i6g3i/1"
        );
        __Ownable_init();
        __DefaultOperatorFilterer_init();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory id,
        uint256[] memory amount,
        bytes memory data
    ) internal override virtual onlyAllowedOperator(from) {
        super._beforeTokenTransfer(operator, from, to, id, amount, data);
    }
}
