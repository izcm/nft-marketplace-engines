// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

abstract contract AccountsHelper is Test {
    struct Actors {
        address order;
        address fill;
    }

    uint256[7] public TEST_KEYS = [1, 2, 3, 4, 5, 6, 7];

    function addrOf(uint256 pk) internal view returns (address) {
        return vm.addr(pk);
    }

    function pkOf(address target) internal view returns (uint256) {
        for (uint256 i = 0; i < TEST_KEYS.length; i++) {
            uint256 pk = TEST_KEYS[i];
            if (vm.addr(pk) == target) {
                return pk;
            }
        }
        revert("Address not in TEST_KEYS");
    }

    function actor(string memory seed) internal view returns (address) {
        uint256 idx = uint256(keccak256(abi.encode(seed))) % TEST_KEYS.length;
        return addrOf(TEST_KEYS[idx]);
    }

    function someActors(
        string memory seed
    ) internal view returns (Actors memory a) {
        a.order = actor(string.concat(seed, "order"));
        a.fill = actor(string.concat(seed, "_fill"));

        uint256 i = 0;
        while (a.order == a.fill) {
            a.fill = actor(string.concat(seed, "_fill_", vm.toString(i)));
            i++;
        }
    }

    function allActors() internal view returns (address[] memory) {
        uint256 count = TEST_KEYS.length;
        address[] memory users = new address[](count);

        for (uint256 i = 0; i < count; i++) {
            users[i] = addrOf(TEST_KEYS[i]);
        }

        return users;
    }
}
