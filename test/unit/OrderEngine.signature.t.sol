// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

// local
import "orderbook/OrderEngine.sol";
import {OrderActs} from "orderbook/libs/OrderActs.sol";

contract OrderEngineSignatureTest is Test {
    using OrderActs for OrderActs.Order;

    OrderEngine public engine;

    uint256 internal userPrivateKey;
    uint256 internal signerPrivateKey;

    address internal collection;

    function setUp() public {
        engine = new OrderEngine();

        userPrivateKey = 0xabc123;
        signerPrivateKey = 0x123abc;

        collection = makeAddr("collection");
    }

    function test_Settle_ValidSignature_Succeeds() public {
        address user = vm.addr(userPrivateKey);
        address signer = vm.addr(signerPrivateKey);

        OrderActs.Order memory order = makeOrder(signer); // order actor = signer
        bytes32 digest = makeDigest(order);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        console.logBytes(abi.encodePacked(r, s, v));

        // vm.startPrank(signer);
    }

    // --------------
    // HELPERS
    // --------------

    function makeOrder(address actor) internal view returns (OrderActs.Order memory) {
        return makeOrder(actor, 0);
    }

    function makeOrder(address actor, uint256 nonce) internal view returns (OrderActs.Order memory) {
        return makeOrder(actor, nonce, 1 ether);
    }

    // TODO: make this accept some seed or make helper seedGenerator to pseudo-randomize fields
    function makeOrder(address actor, uint256 nonce, uint256 price) internal view returns (OrderActs.Order memory) {
        return OrderActs.Order({
            side: OrderActs.Side.Ask,
            actor: actor,
            collection: collection,
            tokenId: 1,
            price: price,
            start: 0,
            end: uint64(block.timestamp + 1 days),
            nonce: nonce
        });
    }

    function makeFill() internal {}

    function makeDigest(OrderActs.Order memory o) internal returns (bytes32) {
        bytes32 msgHash = o.hash();

        return keccak256(abi.encodePacked("\x19\x01", engine.DOMAIN_SEPARATOR, msgHash));
    }
}
