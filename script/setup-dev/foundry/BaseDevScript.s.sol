// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

abstract contract BaseDevScript is Script {
    // DEV ONLY - anvil default funded accounts
    uint256[4] internal DEV_KEYS = [1, 2, 3, 4];

    // addr derived from private key (here 1, 2, 3, 4)
    function devAddr(uint256 i) internal view returns (address) {
        return vm.addr(DEV_KEYS[i]);
    }

    // get private key for a dev address
    function devKey(address who) internal view returns (uint256) {
        for (uint256 i; i < DEV_KEYS.length; i++) {
            address a = devAddr(i);
            if (a == who) {
                return DEV_KEYS[i];
            }
        }
        revert("unknown dev addr");
    }

    function countUntilZero(
        uint256[] memory arr
    ) internal pure returns (uint256) {
        uint256 i = 0;
        while (i < arr.length && arr[i] != 0) {
            i++;
        }
        return i;
    }
}
