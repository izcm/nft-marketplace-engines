// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// core libraries
import {OrderModel} from "orderbook/libs/OrderModel.sol";
import {SignatureOps as SigOps} from "orderbook/libs/SignatureOps.sol";

// scripts
import {BaseDevScript} from "dev/BaseDevScript.s.sol";
import {DevConfig} from "dev/DevConfig.s.sol";

import {OrderSampling} from "dev/logic/OrderSampling.s.sol";
import {SettlementSigner} from "dev/logic/SettlementSigner.s.sol";

// types
import {SignedOrder, SampleMode, Selection} from "dev/state/Types.sol";

// interfaces
import {ISettlementEngine} from "periphery/interfaces/ISettlementEngine.sol";
import {DNFT} from "periphery/interfaces/DNFT.sol";

contract SettleHistory is
    OrderSampling,
    SettlementSigner,
    BaseDevScript,
    DevConfig
{
    // ctx
    uint256 private weekIdx;

    bytes32 private domainSeparator;

    // === ENTRYPOINTS ===

    function runWeek(uint256 _weekIdx) external {
        weekIdx = _weekIdx;
        _bootstrap();
        _jumpToWeek();

        address[] memory collections = readCollections();

        uint256 max;

        for (uint256 i = 0; i < collections.length; i++) {
            max += DNFT(collections[i]).totalSupply();
        }

        OrderModel.Order[] memory orders = new OrderModel.Order[](max);

        {
            // === SELECT TOKENIDS ===

            Selection[] memory selectionAsks = _collect(
                SampleMode.Ask,
                collections
            );
            Selection[] memory selectionBids = _collect(
                SampleMode.Bid,
                collections
            );
            Selection[] memory selectionCbs = _collect(
                SampleMode.CollectionBid,
                collections
            );

            // === BUILD ORDERS ===

            OrderModel.Order[] memory asks = _buildOrdersFromSelections(
                selectionAsks,
                SampleMode.Ask
            );

            OrderModel.Order[] memory bids = _buildOrdersFromSelections(
                selectionBids,
                SampleMode.Bid
            );

            OrderModel.Order[] memory cbs = _buildOrdersFromSelections(
                selectionCbs,
                SampleMode.CollectionBid
            );

            uint256 count = asks.length + bids.length + cbs.length;

            assembly {
                mstore(orders, count)
            }

            // == SIGN ORDERS ===

            // for(uint i = 0; i < )
        }

        SignedOrder[] memory signed = new SignedOrder[](orders.length);

        // === FULFILL OR EXPORT ===

        // === ORDER BY NONCE ===
    }

    function finalize() external {
        _bootstrap();
        _jumpToNow();
    }

    // === SETUP / ENVIRONMENT ===

    function _bootstrap() internal {
        address settlementContract = readSettlementContract();
        address weth = readWeth();

        domainSeparator = ISettlementEngine(settlementContract)
            .DOMAIN_SEPARATOR();

        _initOrderSampling(settlementContract, weth);
        _loadParticipants();
    }

    function _collect(
        SampleMode mode,
        address[] memory collections
    ) internal view returns (Selection[] memory selections) {
        selections = new Selection[](collections.length);

        for (uint256 i = 0; i < collections.length; i++) {
            address collection = collections[i];

            OrderModel.Side side = mode == SampleMode.Ask
                ? OrderModel.Side.Ask
                : OrderModel.Side.Bid;

            bool isCollectionBid = (mode == SampleMode.CollectionBid);

            uint256[] memory tokens = hydrateAndSelectTokens(
                side,
                isCollectionBid,
                collection,
                DNFT(collection).totalSupply(),
                weekIdx
            );

            selections[i] = Selection({
                collection: collection,
                tokenIds: tokens
            });
        }
    }

    function _buildOrdersFromSelections(
        Selection[] memory selections,
        SampleMode mode
    ) internal view returns (OrderModel.Order[] memory orders) {
        // first pass: count
        uint256 total;
        for (uint256 i = 0; i < selections.length; i++) {
            total += selections[i].tokenIds.length;
        }

        orders = new OrderModel.Order[](total);
        uint256 k;

        OrderModel.Side side = mode == SampleMode.Ask
            ? OrderModel.Side.Ask
            : OrderModel.Side.Bid;

        bool isCollectionBid = (mode == SampleMode.CollectionBid);

        for (uint256 i = 0; i < selections.length; i++) {
            Selection memory sel = selections[i];
            address collection = sel.collection;

            for (uint256 j = 0; j < sel.tokenIds.length; j++) {
                orders[k++] = makeOrder(
                    side,
                    isCollectionBid,
                    collection,
                    sel.tokenIds[j]
                );
            }
        }
    }

    // === TIME HELPERS ===

    function _jumpToWeek() internal {
        uint256 startTs = readStartTs();
        vm.warp(startTs + (weekIdx * 7 days));
    }

    function _jumpToNow() internal {
        vm.warp(readNowTs());
    }

    // === PRIVATE ===

    function _isFinalWeek() private view returns (bool) {
        return weekIdx == 4;
        // config.get("final_week_idx").toUint256();
    }

    function _jsonFilePath() private view returns (string memory) {
        return
            string.concat(
                "./data/",
                vm.toString(block.chainid),
                "/orders-raw.json"
            );
    }
}
