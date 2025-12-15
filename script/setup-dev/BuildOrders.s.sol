// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// foundry
import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";
import {console} from "forge-std/console.sol";

// interfaces
import {IERC721} from "@openzeppelin/interfaces/IERC721.sol";

// local scripts
import {BaseDevScript} from "dev-script/BaseDevScript.s.sol";

// local contracts
import {OrderEngine} from "orderbook/OrderEngine.sol";

// local libs
import {OrderActs} from "orderbook/libs/OrderActs.sol";
import {SignatureOps as SigOps} from "orderbook/libs/SignatureOps.sol";
import {OrderBuilder} from "orderbook/libs/OrderBuilder.sol";
import {MarketSim} from "orderbook/libs/MarketSim.sol";

interface DNFT {
    function MAX_SUPPLY() external view returns (uint256);
}

contract BuildOrders is BaseDevScript, Config {
    mapping(address => uint256) internal nonceOf;

    function run() external {
        // --------------------------------
        // PHASE 0: LOAD CONFIG
        // --------------------------------
        _loadConfig("deployments.toml", true);

        logSection("CONFIG");

        uint256 chainId = block.chainid;

        console.log("ChainId: %s", chainId);

        // currencies
        address weth = config.get("weth").toAddress();

        // deployed contracts
        address dNft = config.get("dnft_erc721").toAddress();
        address sigVerifier = config.get("verifying_contract").toAddress();

        logAddress("DNFT    ", dNft);
        logAddress("VERIFIER", sigVerifier);

        // --------------------------------
        // PHASE 1: MAKE ORDERS
        // --------------------------------
        logSection("MAKE ORDERS: ASK");

        OrderActs.Order[] memory orders = _makeOrders(address(dNft), weth);

        // --------------------------------
        // PHASE 2: SIGNING ORDERS
        // --------------------------------
        logSection("SIGNING ORDERS");

        // --- PKs for signing ---
        uint256[] memory participantPKs = readKeys(chainId);
    }

    function _makeOrders(
        address collection,
        address currency
    ) internal returns (OrderActs.Order[] memory) {
        IERC721 token = IERC721(collection);

        uint256[] memory selected = MarketSim.selectTokens(
            collection,
            DNFT(collection).MAX_SUPPLY() / 2,
            3
        );

        OrderActs.Order[] memory orders = new OrderActs.Order[](
            selected.length
        );

        for (uint256 i = 0; i < selected.length; i++) {
            uint256 tokenId = selected[i];
            address owner = token.ownerOf(tokenId);
            uint256 price = MarketSim.priceOf(collection, tokenId);
            uint256 nonce = ++nonceOf[owner];

            orders[i] = OrderBuilder.simpleAsk(
                owner,
                collection,
                currency,
                tokenId,
                price,
                nonce
            );
        }

        return orders;
    }

    function _makeOrderDigestAndSign(
        OrderActs.Order memory order,
        uint256 actorPrivateKey,
        bytes32 domainSeparator
    ) internal returns (OrderActs.Order memory, SigOps.Signature memory) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, OrderActs.hash(order))
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(actorPrivateKey, digest);

        SigOps.Signature memory sig = SigOps.Signature({v: v, r: r, s: s});

        return (order, sig);
    }
}
