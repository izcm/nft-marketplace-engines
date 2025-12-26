// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Config} from "forge-std/Config.sol";

contract DevConfig is Config {
    constructor() {
        _loadConfig("deployments.toml", true);
    }

    function readFunder() internal view returns (address) {
        return config.get("funder").toAddress();
    }

    function readWeth() internal view returns (address) {
        return config.get("weth").toAddress();
    }

    // contract implementing methods `DOMAIN_SEPARATOR()` and `isUserNonceInvalid()`
    function readSettlementContract() internal view returns (address) {
        return config.get("order_engine").toAddress();
    }

    // contract implementing signature verification
    function readSignatureVerifier() internal view returns (address) {
        return config.get("order_engine").toAddress();
    }

    // contract working as the nft transferer
    function readNftTransferAuth() internal view returns (address) {
        return config.get("order_engine").toAddress();
    }

    function readNfts() internal view returns (address[] memory) {
        uint256 count = config.get("nft.count").toUint256();
        address[] memory nfts = new address[](count);
        for (uint256 i; i < count; i++) {
            nfts[i] = config
                .get(string.concat("nft.", vm.toString(i)))
                .toAddress();
        }
        return nfts;
    }
}
