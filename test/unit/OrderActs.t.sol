// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

// local
import {OrderActs} from "orderbook/libs/OrderActs.sol";

contract OrderActsTest is Test {
    using OrderActs for OrderActs.Order;

    /*//////////////////////////////////////////////////////////////
                                IsAsk
    //////////////////////////////////////////////////////////////*/

    function test_IsAsk_ReturnsTrue_ForAsk() public {
        OrderActs.Order memory order = OrderActs.Order({
            side: OrderActs.Side.Ask,
            isCollectionBid: false,
            collection: address(0),
            tokenId: 0,
            currency: address(0),
            price: 0,
            actor: address(0),
            start: 0,
            end: 0,
            nonce: 0
        });

        assertTrue(order.isAsk());
    }

    function test_IsAsk_ReturnsFalse_ForBid() public {
        OrderActs.Order memory order = OrderActs.Order({
            side: OrderActs.Side.Bid,
            isCollectionBid: false,
            collection: address(0),
            tokenId: 0,
            currency: address(0),
            price: 0,
            actor: address(0),
            start: 0,
            end: 0,
            nonce: 0
        });

        assertFalse(order.isAsk());
    }

    /*//////////////////////////////////////////////////////////////
                                IsBid
    //////////////////////////////////////////////////////////////*/

    function test_IsBid_ReturnsTrue_ForBid() public {
        OrderActs.Order memory order = OrderActs.Order({
            side: OrderActs.Side.Bid,
            isCollectionBid: false,
            collection: address(0),
            tokenId: 0,
            currency: address(0),
            price: 0,
            actor: address(0),
            start: 0,
            end: 0,
            nonce: 0
        });

        assertTrue(order.isBid());
    }

    function test_IsBid_ReturnsFalse_ForAsk() public {
        OrderActs.Order memory order = OrderActs.Order({
            side: OrderActs.Side.Ask,
            isCollectionBid: false,
            collection: address(0),
            tokenId: 0,
            currency: address(0),
            price: 0,
            actor: address(0),
            start: 0,
            end: 0,
            nonce: 0
        });

        assertFalse(order.isBid());
    }
}
