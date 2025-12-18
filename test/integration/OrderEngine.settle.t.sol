// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

// token interfaces
import {IERC721} from "@openzeppelin/interfaces/IERC721.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

// local
import {OrderEngine} from "orderbook/OrderEngine.sol";
import {OrderActs} from "orderbook/libs/OrderActs.sol";
import {SignatureOps as SigOps} from "orderbook/libs/SignatureOps.sol";

// helpers
import {OrderHelper} from "test-helpers/OrderHelper.sol";
import {AccountsHelper} from "test-helpers/AccountsHelper.sol";

// mocks
import {MockWETH} from "mocks/MockWETH.sol";
import {MockERC721} from "mocks/MockERC721.sol";

/*
    // === REVERTS ===

    // invalid signature (wrong signer / wrong order fields)
    // reused nonce
    // order.actor == address(0)
    // currency != WETH
    // unsupported collection (not ERC721)

    // === VALID ===

    // NFT transfers seller → fill.actor
    // WETH balances: buyer pays, seller receives (minus fee), protocol gets fee
    // nonce invalidated after settle

    // === SIGNATURE (INTEGRATION ONLY) ===

    // invalid signature causes settle to revert
    // valid signature allows settle to proceed
*/

contract OrderEngineSettleTest is OrderHelper, AccountsHelper {
    using OrderActs for OrderActs.Order;

    uint256 constant DEFAULT_TOKENID = 1;

    OrderEngine orderEngine;
    bytes32 domainSeparator;

    address nftTransferAuthority; // future proofing in case of new transferManager

    MockWETH weth;
    MockERC721 erc721;

    function setUp() public {
        orderEngine = new OrderEngine(address(weth), address(this)); // fee receiver = this
        domainSeparator = orderEngine.DOMAIN_SEPARATOR();

        nftTransferAuthority = address(orderEngine);

        weth = new MockWETH();
        erc721 = new MockERC721();
    }

    /*//////////////////////////////////////////////////////////////
                                REVERTS
    //////////////////////////////////////////////////////////////*/
    function test_Settle_InvalidSenderReverts() public {
        Actors memory actors = someActors("invalid_sender");
        address txSender = vm.addr(TEST_KEYS.length + 1);

        OrderActs.Order memory order = makeOrder(actors.order);
        OrderActs.Fill memory fill = makeFill(actors.fill);
        SigOps.Signature memory sig = dummySig();

        vm.prank(txSender);
        vm.expectRevert(OrderEngine.UnauthorizedFillActor.selector);
        orderEngine.settle(fill, order, sig);
    }

    function test_Settle_ReusedNonceReverts() public {
        Actors memory actors = someActors("reuse_nonce");
        uint256 signerPk = pkOf(actors.order);

        OrderActs.Order memory order = makeOrder(actors.order, address(weth));

        (, SigOps.Signature memory sig) = makeDigestAndSign(
            order,
            domainSeparator,
            signerPk
        );

        OrderActs.Fill memory fill = makeFill(actors.fill);

        // valid nonce
        vm.prank(actors.fill);
        orderEngine.settle(fill, order, sig);

        // replay nonce - should revert
        vm.prank(actors.fill);
        vm.expectRevert(OrderEngine.InvalidNonce.selector);
        orderEngine.settle(fill, order, sig);
    }

    // === INTERNAL HELPERS ===
    function doAllOrderApprovals(OrderActs.Order memory order) internal {
        address collection = order.collection;
        uint256 price = order.price;

        if (order.side == OrderActs.Side.Ask) {
            uint256 tokenId = order.tokenId;
        }
    }

    function approveNftTransfer(address collection, uint256 tokenId) internal {
        approveNftTransfer(collection, nftTransferAuthority, tokenId);
    }

    function approveNftTransfer(
        address collection,
        address operator,
        uint256 tokenId
    ) internal {
        IERC721(collection).approve(operator, tokenId);
    }

    function approveAllowance(uint256 value) internal {
        approveAllowance(weth, address(orderEngine), value);
    }

    function approveAllowance(IERC20 token, uint256 value) internal {
        approveAllowance(token, address(orderEngine), value);
    }

    function approveAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bool success = token.approve(spender, value);

        require(success, "Failed to set allowance");
    }

    function makeFill(
        address actor
    ) internal view returns (OrderActs.Fill memory fill) {
        return OrderActs.Fill({actor: actor, tokenId: DEFAULT_TOKENID});
    }

    function makeFill(
        address actor,
        uint256 tokenId
    ) internal pure returns (OrderActs.Fill memory fill) {
        return OrderActs.Fill({actor: actor, tokenId: tokenId});
    }
}
