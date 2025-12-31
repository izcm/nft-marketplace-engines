// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// foundry
import {console} from "forge-std/console.sol";

// core libraries
import {OrderModel} from "orderbook/libs/OrderModel.sol";
import {SignatureOps as SigOps} from "orderbook/libs/SignatureOps.sol";

// scripts base
import {BaseDevScript} from "dev/BaseDevScript.s.sol";
import {DevConfig} from "dev/DevConfig.s.sol";

// scripts order logic
import {OrdersJson} from "dev/logic/OrdersJson.s.sol";
import {FillBid} from "dev/logic/FillBid.s.sol";

// interfaces
import {IERC20, SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ISettlementEngine} from "periphery/interfaces/ISettlementEngine.sol";

// types
import {SignedOrder} from "dev/state/Types.sol";

contract ExecuteHistory is OrdersJson, FillBid, BaseDevScript, DevConfig {
    using SafeERC20 for IERC20;
    using OrderModel for OrderModel.Order;

    // ctx
    uint256 epoch;

    function run() external {
        // read deployments.toml
        address settlementContract = readSettlementContract();

        _loadParticipants();

        // read signed orders from .json
        SignedOrder[] memory signed = ordersFromJson(
            string.concat(ordersJsonDir(), ".4.json")
        );

        uint256 count = signed.length;

        OrderModel.Fill[] memory fills = new OrderModel.Fill[](count);

        for (uint256 i; i < count; i++) {
            OrderModel.Order memory order = signed[i].order;
            SigOps.Signature memory sig = signed[i].sig;

            OrderModel.Fill memory fill = _produceFill(order);

            // TODO: needs to check for tokenid changes and either:
            // 1. try catch and ignore any invalid settles
            // 2. validate before `settle`
            vm.startBroadcast(pkOf(fill.actor));

            _trySettle(fill, order, sig, settlementContract);

            vm.stopBroadcast();
        }
    }

    function _trySettle(
        OrderModel.Fill memory fill,
        OrderModel.Order memory order,
        SigOps.Signature memory sig,
        address sc
    ) internal {
        try ISettlementEngine(sc).settle(fill, order, sig) {
            console.log("settle ok | tokenId:", order.tokenId);
        } catch Error(string memory reason) {
            // Error(string)
            console.log("settle reverted (string):", reason);
        } catch (bytes memory data) {
            // custom errors
            console.log("settle reverted (custom/low-level)");
            console.logBytes(data);
        }
    }

    function _produceFill(
        OrderModel.Order memory order
    ) internal view returns (OrderModel.Fill memory) {
        if (order.isAsk()) {
            return _fillAsk(order.actor, order.nonce);
        } else if (order.isBid()) {
            return fillBid(order);
        } else {
            revert("Invalid Order Side");
        }
    }

    function _fillAsk(
        address orderActor,
        uint256 seed
    ) internal view returns (OrderModel.Fill memory) {
        return
            OrderModel.Fill({
                tokenId: 0,
                actor: otherParticipant(orderActor, seed)
            });
    }

    // === TIME HELPERS ===

    function _jumpToWeek() internal {
        uint256 startTs = readStartTs();
        vm.warp(startTs + (epoch * 7 days));
    }

    function _jumpToNow() internal {
        vm.warp(readNowTs());
    }
}
