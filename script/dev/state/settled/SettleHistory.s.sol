// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// core libraries
import {OrderModel} from "orderbook/libs/OrderModel.sol";
import {SignatureOps as SigOps} from "orderbook/libs/SignatureOps.sol";

// scripts
import {BaseDevScript} from "dev/BaseDevScript.s.sol";
import {BaseSettlement} from "dev/BaseSettlement.s.sol";
import {DevConfig} from "dev/DevConfig.s.sol";
import {OrderSampling} from "dev/logic/OrderSampling.s.sol";

struct SignedOrder {
    OrderModel.Order order;
    SigOps.Signature sig;
}

contract SettleHistory is
    BaseDevScript,
    BaseSettlement,
    OrderSampling,
    DevConfig
{
    // ctx
    uint256 private weekIdx;

    // === ENTRYPOINTS ===

    function runWeek(uint256 _weekIdx) external {
        weekIdx = _weekIdx;
        _bootstrap();
        _jumpToWeek();

        _collect();
    }

    function finalize() external {
        _bootstrap();
        _jumpToNow();
    }

    // === SETUP / ENVIRONMENT ===

    function _bootstrap() internal {
        address settlementContract = readSettlementContract();
        address weth = readWeth();

        address[] memory collections = readCollections();

        _initBaseSettlement(settlementContract, weth);
        _initOrderSampling(0, 0, collections);
    }

    function _handleSigned(SignedOrder[] memory order) internal {
        if (!_isFinalWeek()) {
            // order by nonce and fulfill
        } else {
            // write to
        }
    }

    function _collect() internal {
        // === collect => build ===

        {
            collectAsks(); // collects and stores tokenids with `ask` seed

            SignedOrder[] memory signed = _buildAndSignAsks();

            // _persistSignedOrders(signed, string.concat(basePath, ".ask.json"));
        }

        // BIDS

        {
            collectBids(); // collects and stores tokenids with `ask` seed

            SignedOrder[] memory signed = _buildAndSignBids();

            // _persistSignedOrders(signed, string.concat(basePath, ".bid.json"));
        }

        // COLLECTION BIDS

        {
            collectCollectionBids(); // collects and stores tokenids with `ask` seed

            SignedOrder[] memory signed = _buildAndSignCollectionBids();

            // _persistSignedOrders(signed, string.concat(basePath, ".cb.json"));
        }
    }

    function _buildAndSignAsks() internal view returns (SignedOrder[] memory) {
        return _buildAndSignOrders(OrderModel.Side.Ask, false);
    }

    function _buildAndSignBids() internal view returns (SignedOrder[] memory) {
        return _buildAndSignOrders(OrderModel.Side.Bid, false);
    }

    function _buildAndSignCollectionBids()
        internal
        view
        returns (SignedOrder[] memory)
    {
        return _buildAndSignOrders(OrderModel.Side.Bid, true);
    }

    function _buildAndSignOrders(
        OrderModel.Side side,
        bool isCollectionBid
    ) internal view returns (SignedOrder[] memory) {
        OrderModel.Order[] memory orders = buildOrders(side, isCollectionBid); // builds the orders stored in `OrderSampling.collectionSelected`

        uint256 count = orders.length;

        SignedOrder[] memory signed = new SignedOrder[](count);

        for (uint256 i = 0; i < count; i++) {
            OrderModel.Order memory order = orders[i];

            uint256 pk = pkOf(order.actor);
            require(pk != 0, "NO PK FOR ACTOR");

            (SigOps.Signature memory sig) = signOrder(order, pk);

            signed[i] = SignedOrder({order: order, sig: sig});
        }

        return signed;
    }

    // === TIME HELPERS ===

    function _jumpToWeek() internal {
        uint256 startTs = _readStartTimestamp();
        vm.warp(startTs + (weekIdx * 7 days));
    }

    function _jumpToNow() internal {
        vm.warp(config.get("now_ts").toUint256());
    }

    // === PRIVATE ===

    // only this script uses reads timestamp so readers are moved here
    function _readStartTimestamp() private view returns (uint256) {
        return config.get("history_start_ts").toUint256();
    }

    function _isFinalWeek() private view returns (bool) {
        return config.get("final_week_idx").toUint256() == weekIdx;
    }

    function _basePath() private view returns (string memory) {
        return
            string.concat("./data/", vm.toString(block.chainid), "/orders-raw");
    }
}
