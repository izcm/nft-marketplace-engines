// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {OrderActs} from "orderbook/libs/OrderActs.sol";
import {SettlementRoles} from "orderbook/libs/SettlementRoles.sol";
import {OrderHelper} from "test-helpers/OrderHelper.sol";

/// NOTE:
/// This test suite exclusively verifies `SettlementRoles.resolve` behavior.
/// It assumes `OrderHelper.makeOrder` correctly constructs valid `Order` structs.
/// `OrderHelper` is tested independently in `./OrderHelper.t.sol`.

contract SettlementRolesTest is OrderHelper {
    address orderActor;
    address fillActor;

    function setUp() public {
        orderActor = makeAddr("order_actor");
        fillActor = makeAddr("fill_actor");

        bytes32 dummyDomainSeparator = bytes32(
            keccak256(abi.encode("dummy_separator"))
        );

        address dummyCollection = makeAddr("dummy_collection");
        address dummyCurrency = makeAddr("dummy_currency");

        _initOrderHelper(dummyDomainSeparator, dummyCollection, dummyCurrency);
    }

    /*//////////////////////////////////////////////////////////////
                                SUCCESS
    //////////////////////////////////////////////////////////////*/

    function test_Resolve_Ask_ReturnsCorrectRoles() public {
        OrderActs.Order memory order = makeOrder(
            OrderActs.Side.Ask,
            false,
            orderActor
        );

        // ensure fill tokenId is ignored for asks
        OrderActs.Fill memory fill = OrderActs.Fill({
            tokenId: 999,
            actor: fillActor
        });

        (address nftHolder, address spender, uint256 tokenId) = SettlementRoles
            .resolve(fill, order);

        assertEq(nftHolder, orderActor);
        assertEq(spender, fillActor);
        assertEq(tokenId, order.tokenId);
    }

    function test_Resolve_Bid_SpecificToken_ReturnsCorrectRoles() public {
        OrderActs.Order memory order = makeOrder(
            OrderActs.Side.Bid,
            false,
            orderActor
        );

        OrderActs.Fill memory fill = OrderActs.Fill({
            tokenId: 888,
            actor: fillActor
        });

        (address nftHolder, address spender, uint256 tokenId) = SettlementRoles
            .resolve(fill, order);

        assertEq(nftHolder, fillActor);
        assertEq(spender, orderActor);
        assertEq(tokenId, order.tokenId);
    }

    function test_Resolve_Bid_CollectionBid_UsesFillTokenId() public {
        OrderActs.Order memory order = makeOrder(
            OrderActs.Side.Bid,
            true,
            orderActor
        );

        uint256 collectionTokenId = 777;

        OrderActs.Fill memory fill = OrderActs.Fill({
            tokenId: collectionTokenId,
            actor: fillActor
        });

        (address nftHolder, address spender, uint256 tokenId) = SettlementRoles
            .resolve(fill, order);

        assertEq(nftHolder, fillActor);
        assertEq(spender, orderActor);
        assertEq(tokenId, collectionTokenId);
    }

    /*//////////////////////////////////////////////////////////////
                                REVERTS
    //////////////////////////////////////////////////////////////*/

    function test_Resolve_Order_InvalidSideReverts() public {
        OrderActs.Order memory order = OrderActs.Order({
            side: OrderActs.Side._COUNT, // invalid on purpose
            isCollectionBid: false,
            collection: address(0),
            tokenId: 1,
            currency: address(0),
            price: 1 ether,
            actor: orderActor,
            start: 0,
            end: type(uint64).max,
            nonce: 0
        });

        OrderActs.Fill memory fill = OrderActs.Fill({
            tokenId: 1,
            actor: fillActor
        });

        vm.expectRevert(SettlementRoles.InvalidOrderSide.selector);
        this._resolveExternal(fill, order);
    }

    // generates CALL opCode
    function _resolveExternal(
        OrderActs.Fill memory f,
        OrderActs.Order memory o
    ) external pure {
        SettlementRoles.resolve(f, o);
    }
}
