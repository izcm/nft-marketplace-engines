// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

abstract contract BaseDevScript is Script {
    // DEV ONLY - anvil default funded accounts
    address[4] internal DEV_ADDRS = [
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
        0x90F79bf6EB2c4f870365E785982E1f101E93b906
    ];

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

    // **ANVIL DEFAULT ACCOUNTS** (!!!)
    function devKey(address who) internal pure returns (bytes32) {
        if (who == 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) {
            return
                0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }

        if (who == 0x70997970C51812dc3A010C7d01b50e0d17dc79C8) {
            return
                0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        }

        if (who == 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC) {
            return
                0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        }

        if (who == 0x90F79bf6EB2c4f870365E785982E1f101E93b906) {
            return
                0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;
        }

        revert("unknown dev addr");
    }
}
