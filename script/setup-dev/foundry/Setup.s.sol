// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Config} from "forge-std/Config.sol";
import {console} from "forge-std/console.sol";

// local
import {BaseDevScript} from "dev-script/BaseDevScript.s.sol";
import {OrderEngine} from "orderbook/OrderEngine.sol";

// TODO: cryptopunks is not erc721 compatible, custom wrapper l8r?
// https://docs.openzeppelin.com/contracts/4.x/api/token/erc721
interface IERC721 {
    function setApprovalForAll(address operator, bool approved) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Setup is BaseDevScript, Config {
    OrderEngine public orderEngine;

    function run() external {
        // --------------------------------
        // PHASE 0: LOAD CONFIG + SETUP
        // --------------------------------

        _loadConfig("deployments.toml", true);

        uint256 chainId = block.chainid;
        console.log("Deploying to chain: %s", chainId);

        address azukiAddr = config.get("azuki_addr").toAddress();

        // select tokens
        (uint256[] memory ids) = selectTokens(azukiAddr, 10, 2);

        // get number of tokens
        uint256 length = countUntilZero(ids);

        // --------------------------------
        // PHASE 1: PRANK OWNERS
        // --------------------------------

        address[] memory owners = new address[](length);

        // read owner
        for (uint256 i = 0; i < length; i++) {
            owners[i] = readOwnerOf(azukiAddr, ids[i]);
            console.log("Owner of token %s: %s", ids[i], owners[i]);
        }

        // impersonate each owner
        for (uint256 i = 0; i < length; i++) {
            vm.prank(owners[i]);
            // transfer selected tokens to some devAddr
            IERC721(azukiAddr).transferFrom(
                owners[i], // ← ACTUAL OWNER
                devAddr(1), // ← YOU
                ids[i]
            );
        }

        // --------------------------------
        // PHASE 2: BROADCAST - FUND
        // --------------------------------

        // - fund ETH to DEV wallets
        // - wrap ETH =>  WETH

        // --------------------------------
        // PHASE 3: BROADCAST - APPROVALS
        // --------------------------------

        // - WETH allowance to marketplace
        // - Approve marketplace

        /*
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
    ) internal pure returns (uint256[] memory) {
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
        return ids;
    }

    function readOwnerOf(
        address tokenContract,
        uint256 tokenId
    ) internal view returns (address) {
        return IERC721(tokenContract).ownerOf(tokenId);
    }
}
