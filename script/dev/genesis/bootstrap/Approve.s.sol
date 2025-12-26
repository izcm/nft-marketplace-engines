// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Config} from "forge-std/Config.sol";
import {console} from "forge-std/console.sol";

// scripts
import {BaseDevScript} from "dev/BaseDevScript.s.sol";
import {DevConfig} from "dev/DevConfig.s.sol";

// interfaces
import {IERC721} from "@openzeppelin/interfaces/IERC721.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

contract Approve is BaseDevScript, DevConfig {
    function run() external {
        // --------------------------------
        // PHASE 0: LOAD CONFIG
        // --------------------------------
        logSection("LOAD CONFIG");

        address weth = readWeth();
        address nftTransferAuth = readNftTransferAuth();

        address[] memory nfts = readNfts();

        address dNft = nfts[0];

        logAddress("DNFT       ", dNft);
        logAddress("MARKETPLACE", nftTransferAuth);

        // --- PKs for broadcasting ---
        uint256[] memory participantPks = readKeys();
        uint256 participantCount = participantPks.length;

        // --------------------------------
        // PHASE 1: MARKETPLACE TRANSFER
        // --------------------------------
        logSection("APPROVE MARKETPLACE FOR NFTs");

        IERC721 nftToken = IERC721(address(dNft));

        for (uint256 i = 0; i < participantCount; i++) {
            vm.startBroadcast(participantPks[i]);
            nftToken.setApprovalForAll(nftTransferAuth, true);
            vm.stopBroadcast();

            address owner = addrOf(participantPks[i]);
            console.log(
                "%s HAS APPROVED DMRKT FOR ALL: ",
                owner,
                nftToken.isApprovedForAll(owner, nftTransferAuth)
            );
        }

        // --------------------------------
        // PHASE 2: WETH ALLOWANCE
        // --------------------------------
        logSection("APPROVE WETH ALLOWANCE FOR MARKETPLACE");

        // DEV-ONLY:
        // Infinite approval used ONLY for local fork / deterministic setup.
        // Production flow uses exact per-owner exposure-based allowances.
        IERC20 wethToken = IERC20(weth);
        uint256 allowance = type(uint256).max;

        for (uint256 i = 0; i < participantCount; i++) {
            vm.startBroadcast(participantPks[i]);
            wethToken.approve(nftTransferAuth, allowance);
            vm.stopBroadcast();

            address owner = addrOf(participantPks[i]);
            console.log(
                "%s HAS APPROVED ALLOWANCE FOR MARKETPLACE: ",
                owner,
                wethToken.allowance(owner, nftTransferAuth)
            );
        }
    }
}
