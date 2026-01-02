// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

// core libraries
import {OrderModel} from "orderbook/libs/OrderModel.sol";
import {SignatureOps as SigOps} from "orderbook/libs/SignatureOps.sol";

// types
import {SignedOrder, ActorNonce} from "dev/state/Types.sol";

abstract contract OrdersJson is Script {
    // === JSON SPECIFIC SCHEMAS ===

    struct PersistedOrdersJson {
        uint256 chainId;
        SignedOrdersJson[] signed;
    }

    struct PersistedNoncesJson {
        ActorNonce[] nonces;
    }

    struct SignedOrdersJson {
        address actor;
        address collection;
        address currency;
        uint64 end;
        bool isCollectionBid;
        uint256 nonce;
        uint256 price;
        OrderModel.Side side;
        SignatureJson sig;
        uint64 start;
        uint256 tokenId;
    }

    // struct has to match json alphabetical order => cannot use SigOps.Signature
    struct SignatureJson {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function epochOrdersPath(
        uint256 epoch
    ) internal view returns (string memory) {
        string memory dir = string.concat(_stateDir(), _epochDir(epoch));
        string memory out = "/orders.json";

        return string.concat(dir, out);
    }

    function epochNoncesPath(
        uint256 epoch
    ) internal view returns (string memory) {
        string memory dir = string.concat(_stateDir(), _epochDir(epoch));
        string memory out = "/nonces.json";

        return string.concat(dir, out);
    }

    // === TO JSON ===

    function ordersToJson(
        SignedOrder[] memory signed,
        string memory path
    ) internal {
        string memory root = "orders";

        // metadata
        vm.serializeUint(root, "chainId", block.chainid);

        string[] memory entries = new string[](signed.length);

        for (uint256 i = 0; i < signed.length; i++) {
            SignedOrder memory item = signed[i];

            string memory oKey = string.concat("order_", vm.toString(i));

            entries[i] = _serializeOrdersJson(item.order, oKey);

            // ---- signature ----
            SigOps.Signature memory sig = item.sig;

            string memory sKey = string.concat(oKey, "_sig");

            vm.serializeUint(sKey, "v", sig.v);
            vm.serializeBytes32(sKey, "r", sig.r);
            string memory sigOut = vm.serializeBytes32(sKey, "s", sig.s);

            string memory out = vm.serializeString(oKey, "sig", sigOut);

            entries[i] = out;
        }

        string memory finalJson = vm.serializeString(root, "signed", entries);

        vm.writeJson(finalJson, path);
    }

    // Enables BuildHistory.s.sol keeping track of nonces between epochs
    function noncesToJson(
        ActorNonce[] memory nonces,
        string memory path
    ) internal {
        string memory root = "nonces";

        string[] memory entries = new string[](nonces.length);

        for (uint256 i = 0; i < nonces.length; i++) {
            string memory k = string.concat("nonce_", vm.toString(i));

            vm.serializeAddress(k, "actor", nonces[i].actor);
            string memory out = vm.serializeUint(k, "nonce", nonces[i].nonce);

            entries[i] = out;
        }

        string memory finalJson = vm.serializeString(root, "nonces", entries);
        vm.writeJson(finalJson, path);
    }

    // == FROM JSON ===

    function ordersFromJson(
        string memory path
    ) internal view returns (SignedOrder[] memory signed) {
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);

        PersistedOrdersJson memory parsed = abi.decode(
            data,
            (PersistedOrdersJson)
        );
        uint256 count = parsed.signed.length;

        signed = new SignedOrder[](count);

        for (uint256 i = 0; i < count; i++) {
            signed[i] = _fromSignedOrdersJson(parsed.signed[i]);
        }
    }

    function noncesFromJson(
        string memory path
    ) internal view returns (ActorNonce[] memory nonces) {
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);

        PersistedNoncesJson memory parsed = abi.decode(
            data,
            (PersistedNoncesJson)
        );

        uint256 count = parsed.nonces.length;

        nonces = new ActorNonce[](count);

        for (uint256 i = 0; i < count; i++) {
            nonces[i] = parsed.nonces[i];
        }
    }

    // === PRIVATE FUNCTIONS ===

    // --- path builders ---

    function _stateDir() private view returns (string memory) {
        return string.concat("./data/", vm.toString(block.chainid), "/state/");
    }

    function _epochDir(uint256 epoch) private pure returns (string memory) {
        return string.concat("epoch_", vm.toString(epoch));
    }

    // --- serializers ---

    function _serializeOrdersJson(
        OrderModel.Order memory o,
        string memory objKey
    ) private returns (string memory) {
        string memory key = objKey;

        // ---- order ----
        vm.serializeUint(key, "side", uint256(o.side));
        vm.serializeAddress(key, "actor", o.actor);
        vm.serializeBool(key, "isCollectionBid", o.isCollectionBid);
        vm.serializeAddress(key, "collection", o.collection);
        vm.serializeUint(key, "tokenId", o.tokenId);
        vm.serializeUint(key, "price", o.price);
        vm.serializeAddress(key, "currency", o.currency);
        vm.serializeUint(key, "start", o.start);
        vm.serializeUint(key, "end", o.end);
        vm.serializeUint(key, "nonce", o.nonce);

        return key;
    }

    function _fromSignedOrdersJson(
        SignedOrdersJson memory jso
    ) internal pure returns (SignedOrder memory signed) {
        signed.order = OrderModel.Order({
            side: jso.side,
            isCollectionBid: jso.isCollectionBid,
            collection: jso.collection,
            tokenId: jso.tokenId,
            currency: jso.currency,
            price: jso.price,
            actor: jso.actor,
            start: jso.start,
            end: jso.end,
            nonce: jso.nonce
        });

        signed.sig = SigOps.Signature({
            v: jso.sig.v,
            r: jso.sig.r,
            s: jso.sig.s
        });
    }
}
