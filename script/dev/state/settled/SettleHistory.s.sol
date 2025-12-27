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

// logging
import {console} from "forge-std/console.sol";

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
        logSection("SETTLE HISTORY");
        console.log("Week: %s", _weekIdx);
        logSeparator();

        weekIdx = _weekIdx;
        _bootstrap();
        _jumpToWeek();

        address[] memory collections = readCollections();
        console.log("Collections: %s", collections.length);

        uint256 max;

        for (uint256 i = 0; i < collections.length; i++) {
            uint256 supply = DNFT(collections[i]).totalSupply();
            max += supply;
            console.log("  Collection %s: %s NFTs", i, supply);
        }
        console.log("Total NFTs: %s", max);

        OrderModel.Order[] memory orders;

        {
            // === SELECT TOKENIDS ===
            logSection("SELECTION");

            Selection[] memory selectionAsks = _collect(
                SampleMode.Ask,
                collections
            );
            console.log("Ask selections: %s", selectionAsks.length);

            Selection[] memory selectionBids = _collect(
                SampleMode.Bid,
                collections
            );
            console.log("Bid selections: %s", selectionBids.length);

            Selection[] memory selectionCbs = _collect(
                SampleMode.CollectionBid,
                collections
            );
            console.log("Collection bid selections: %s", selectionCbs.length);

            // === ALLOCATE MEMORY ===
            logSection("ORDER CREATION");

            uint256 count;

            for (uint256 i = 0; i < selectionAsks.length; i++) {
                count += selectionAsks[i].tokenIds.length;
            }
            for (uint256 i = 0; i < selectionBids.length; i++) {
                count += selectionBids[i].tokenIds.length;
            }
            for (uint256 i = 0; i < selectionCbs.length; i++) {
                count += selectionCbs[i].tokenIds.length;
            }

            console.log("Total orders to create: %s", count);
            orders = new OrderModel.Order[](count);

            uint256 idx;

            // === MAKE ORDERS ===

            for (uint256 i = 0; i < selectionAsks.length; i++) {
                Selection memory sel = selectionAsks[i];
                for (uint256 j = 0; j < sel.tokenIds.length; j++) {
                    orders[idx++] = makeOrder(
                        OrderModel.Side.Ask,
                        false,
                        sel.collection,
                        sel.tokenIds[j]
                    );
                }
            }

            for (uint256 i = 0; i < selectionBids.length; i++) {
                Selection memory sel = selectionBids[i];
                for (uint256 j = 0; j < sel.tokenIds.length; j++) {
                    orders[idx++] = makeOrder(
                        OrderModel.Side.Bid,
                        false,
                        sel.collection,
                        sel.tokenIds[j]
                    );
                }
            }

            for (uint256 i = 0; i < selectionCbs.length; i++) {
                Selection memory sel = selectionCbs[i];
                for (uint256 j = 0; j < sel.tokenIds.length; j++) {
                    orders[idx++] = makeOrder(
                        OrderModel.Side.Bid,
                        true,
                        sel.collection,
                        sel.tokenIds[j]
                    );
                }
            }
        }

        // === SIGN ORDERS ===
        logSection("SIGNING");

        SignedOrder[] memory signed = new SignedOrder[](orders.length);

        for (uint256 i = 0; i < orders.length; i++) {
            SigOps.Signature memory sig = signOrder(
                domainSeparator,
                orders[i],
                pkOf(orders[i].actor)
            );

            signed[i] = SignedOrder(orders[i], sig);
        }
        console.log("Orders signed: %s", signed.length);

        logSection("COMPLETE");
        console.log(
            "Week %s ready with %s signed orders",
            weekIdx,
            signed.length
        );
        logSeparator();

        // === ORDER BY NONCE ===

        // === FULFILL OR EXPORT ===
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
