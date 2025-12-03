// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

library Auth {
    struct Signature {
        uint8 v; // Y-parity - 27 or 28 always
        bytes32 r;
        bytes32 s;
    }
}
