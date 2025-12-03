// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

// Explicit namespace imports to avoid any ambiguity in maintenance / audits
import "./libs/OrderActs.sol";
import "./libs/Auth.sol";

contract OrderEngine {
    using OrderActs for OrderActs.Order;

    bytes32 public immutable DOMAIN_SEPERATOR;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceValid;

    constructor() {
        // load to memory => compute hash
        DOMAIN_SEPERATOR = keccak256(
            abi.encode(
                // EIP-712 domain type hash
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                // nameHash
                0x997dc85543e54e3a10f066eed263ff8d0cbf9f87e862f32fce17b110cadc23f2, // "dmrkt"
                // versionHash
                0x044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d, // "0"
                // static types => fed directly
                block.chainid,
                address(this)
            )
        );
    }

    /// Matches a `Fill` request to an existing `Order`
    function settle(OrderActs.Fill calldata fill, OrderActs.Order calldata order, Auth.Signature calldata sig)
        external {
        //
    }

    // --------------
    // INTERNAL
    // --------------
    function verifyOrder() internal {
        // validate signature
    }
}
