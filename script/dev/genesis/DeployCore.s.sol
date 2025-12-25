// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Config} from "forge-std/Config.sol";
import {console} from "forge-std/console.sol";

// core contracts
import {OrderEngine} from "orderbook/OrderEngine.sol";

// periphery contracts
import {DMrktGremlin} from "nfts/DMrktGremlin.ERC721.sol";
import {DMrktSeal} from "nfts/DMrktSeal.ERC721.sol";

// scripts
import {BaseDevScript} from "dev/BaseDevScript.s.sol";

contract DeployCore is BaseDevScript, Config {
    function run() external {
        // --------------------------------
        // PHASE 0: LOAD CONFIG
        // --------------------------------
        _loadConfig("deployments.toml", true);

        logSection("LOAD CONFIG");

        uint256 chainId = block.chainid;

        console.log("ChainId: %s", chainId);

        address weth = config.get("weth").toAddress();
        uint256 funderPk = uint256(uint256(vm.envUint("PRIVATE_KEY")));

        // --------------------------------
        // PHASE 1: DEPLOY MARKETPLCE & NFTS
        // --------------------------------
        logSection("DEPLOY CORE CONTRACTS");

        // since the script uses the same private key its not necessary but I like to be explicit
        vm.startBroadcast(funderPk);

        // deploy core
        OrderEngine orderEngine = new OrderEngine(weth, msg.sender);

        // deploy periphery
        DMrktGremlin gremlin = new DMrktGremlin();
        DMrktSeal seal = new DMrktSeal();

        vm.stopBroadcast();

        // log deployments
        logDeployment("OrderEngine", address(orderEngine));

        logDeployment("DMrktGremlin", address(gremlin));
        logDeployment("DMrktGremlin", address(seal));

        // ---  write deployed addrs to .toml ---

        // marketplace logic

        // contract must implement the methods `DOMAIN_SEPARATOR()` and `isUserNonceInvalid()`
        config.set("settlement_contract", address(orderEngine));

        // contract must implement signature verification
        config.set("signature_verifier", address(orderEngine)); // for our order builder

        // nft contracts
        config.set("dmrktgremlin", address(gremlin));
        config.set("dmrktseal", address(seal));
    }
}
