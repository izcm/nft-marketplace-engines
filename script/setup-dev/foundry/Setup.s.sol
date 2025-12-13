// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";
import {console} from "forge-std/console.sol";

// local
import {BaseDevScript} from "dev-script/BaseDevScript.s.sol";
import {OrderEngine} from "orderbook/OrderEngine.sol";

// TODO: cryptopunks is not erc721 compatible, custom wrapper l8r?
interface IERC721 {
    function setApprovalForAll(address operator, bool approved) external;
    function ownerOf(uint256 tokenId) external;
}

contract Setup is BaseDevScript, Config {
    OrderEngine public orderEngine;

    function run() external {
        _loadConfig("deployments.toml", true);

        uint256 chainId = block.chainid;
        console.log("Deploying to chain: %s", chainId);

        address azukiAddr = config.get("azuki_addr").toAddress();
        console.log(azukiAddr);

        // select tokens
        (uint256[] memory ids, uint256 count) = selectTokens(azukiAddr, 10, 2);

        // get number of tokens
        uint256 length = countUntilZero(ids);
        // read owner

        // impersonate each owner
        /* vm.startBroadcast();
        // transfer selected tokens to some devAddr

        // fund devAddrs

        // impersonate devAddrs and buy WETH

        // WETH allowance marketplace

        //

        orderEngine = new OrderEngine();
        vm.stopBroadcast();

        // TODO: write the addr back to development.toml
        // console.log("\nEngine Deployed: %s", address(orderEngine));

        console.log(
            "\nDeployment complete! Addresses saved to deployments.toml"
        );
        */
    }

    function selectTokens(
        address tokenContract,
        uint256 roof,
        uint8 mod
    ) internal returns (uint256[] memory, uint256) {
        uint256 count = 0;
        uint256[] memory ids = new uint256[](roof);

        // start at 1 cuz we don't care enough to check if contract skips #0 / no
        for (uint256 i = 1; i <= roof; i++) {
            bytes32 h = keccak256(abi.encode(tokenContract, i));
            if (uint256(h) % mod == 0) {
                ids[count] = i;
                count++;
            }
        }
        return (ids, count);
    }

    function readOwnerOf(address tokenContract, uint256 tokenId) internal {
        IERC721(tokenContract).ownerOf(tokenId);
        console.log("Owner of token %s", tokenId);
    }
}
