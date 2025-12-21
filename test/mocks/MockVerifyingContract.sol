// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "orderbook/libs/OrderActs.sol";
import {SignatureOps as SigOps} from "orderbook/libs/SignatureOps.sol";

contract MockVerifyingContract {
    using OrderActs for OrderActs.Order;
    using SigOps for SigOps.Signature;

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor(bytes32 domainSeparator) {
        DOMAIN_SEPARATOR = domainSeparator;
    }

    function verify(
        OrderActs.Order calldata order,
        SigOps.Signature calldata sig
    ) external view returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = sig.vrs();

        SigOps.verify(DOMAIN_SEPARATOR, order.hash(), order.actor, v, r, s);

        return true;
    }
}
