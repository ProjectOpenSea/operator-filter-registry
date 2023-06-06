// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";
import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {TestableExampleERC721} from "../example/ExampleERC721.t.sol";

interface IOperatorFilterRegistry {
    function filteredOperators(address addr) external returns (address[] memory);
}

interface IERC721SeaDrop {
    function owner() external view returns (address);

    function setMaxSupply(uint256 newMaxSupply) external;

    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop) external;

    function mintSeaDrop(address minter, uint256 quantity) external;

    function totalSupply() external view returns (uint256);
}

contract ValidationTest is Test {
    address constant LOOKSRAREV2_TRANSFER_MANAGER = 0x000000000060C4Ca14CfC4325359062ace33Fe3D;

    address constant CANONICAL_OPERATOR_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;
    address constant CANONICAL_REGISTRANT = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    // Contract to test against
    /// The token contract to test against.
    address contractAddress;

    /// The token ID to test against.
    uint256 tokenId;

    /// The owner of the NFT.
    address owner;

    /// The filtered operators to check compliance against.
    address[] filteredOperators;

    /// The canonical cross-chain SeaDrop contract.
    address seaDrop = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;

    /// The INonFungibleSeaDropToken interface ID.
    bytes4 constant SEADROP_TOKEN_INTERFACE_ID = 0x1890fe8e;

    function setUp() public virtual {
        // Fork network
        try vm.envString("NETWORK") returns (string memory envNetwork) {
            vm.createSelectFork(getChain(envNetwork).rpcUrl);
        } catch {
            // fallback to mainnet
            vm.createSelectFork(getChain("mainnet").rpcUrl);
        }

        filteredOperators =
            IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY).filteredOperators(CANONICAL_REGISTRANT);

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

    function testValidateEnforcement() public {
        IERC165 tokenContract = IERC165(contractAddress);
        try tokenContract.supportsInterface(type(IERC721).interfaceId) returns (bool _supports) {
            if (_supports) {
                _testERC721();
            } else {
                if (tokenContract.supportsInterface(type(IERC1155).interfaceId)) {
                    _testERC1155();
                } else {
                    // else fall back to ERC721
                    console2.log("ERC165 check returned false for both ERC721 and ERC1155, falling back to ERC721.");
                    _testERC721();
                }
            }
        } catch {
            // if ERC165 check fails, fall back to ERC721
            console2.log("ERC165 check reverted, falling back to ERC721.");
            _testERC721();
        }
    }

    function _testERC721() internal {
        // Cast the contract to an ERC721.
        IERC721 nftContract = IERC721(contractAddress);

        // Get the current owner of the NFT
        try nftContract.ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
            // If the tokenId doesn't exist, check if this is a SeaDrop token,
            // which we can simulate a mint for.
            if (!nftContract.supportsInterface(SEADROP_TOKEN_INTERFACE_ID)) {
                revert("The token reverted on ownerOf(tokenId) and it is not a SeaDrop token.");
            }

            // Cast the contract to a SeaDrop token.
            IERC721SeaDrop seaDropToken = IERC721SeaDrop(contractAddress);

            // Set the token owner to an address, it doesn't matter who this is.
            owner = makeAddr("alice");

            // Increase the max supply by 1 so we can mint.
            vm.startPrank(seaDropToken.owner());
            uint256 newMaxSupply = seaDropToken.totalSupply() + 1;
            seaDropToken.setMaxSupply(newMaxSupply);

            // Ensure SeaDrop is allowed to mint.
            address[] memory allowedSeaDrop = new address[](1);
            allowedSeaDrop[0] = seaDrop;
            seaDropToken.updateAllowedSeaDrop(allowedSeaDrop);
            vm.stopPrank();

            // Mint the token to the token owner.
            vm.prank(seaDrop);
            seaDropToken.mintSeaDrop(owner, 1);

            // SeaDrop tokens have a start token id of 1,
            // so the newly minted token id should be totalSupply()
            tokenId = seaDropToken.totalSupply();
        }

        for (uint256 i = 0; i < filteredOperators.length; i++) {
            // skip LOOKSRAREV2_TRANSFER_MANAGER as updates are subject to grace period
            if (filteredOperators[i] == LOOKSRAREV2_TRANSFER_MANAGER) {
                continue;
            }
            address operator = filteredOperators[i];

            // Try to set approval for the operator.
            vm.startPrank(owner);
            try nftContract.setApprovalForAll(operator, true) {
                // Blocking approvals is not required, so continue to check transfers.
            } catch {
                // Continue to test transfer methods, since marketplace approvals can be
                // hard-coded into contracts.
            }

            // Also include per-token approvals as those may not be blocked.
            try nftContract.approve(operator, tokenId) {
                // Continue to check transfers.
            } catch {
                // Continue to test transfer methods, since marketplace approvals can be
                // hard-coded into contracts.
            }
            vm.stopPrank();

            // Ensure operator is not able to transfer the token.
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

    function _testERC1155() internal {
        // Cast the contract to an ERC1155.
        IERC1155 nftContract = IERC1155(contractAddress);

        for (uint256 i = 0; i < filteredOperators.length; i++) {
            address operator = filteredOperators[i];

            // Try to set approval for the operator.
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

            // Ensure operator is not able to transfer the token.
            vm.startPrank(operator);
            vm.expectRevert();
            nftContract.safeTransferFrom(owner, address(1), tokenId, 1, "");

            vm.expectRevert();
            nftContract.safeBatchTransferFrom(owner, address(1), tokenIds, amounts, "");
            vm.stopPrank();
        }
    }
}
