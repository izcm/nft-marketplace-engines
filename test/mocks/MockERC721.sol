// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 public currentTokenId;

    constructor() ERC721("Mock", "MOCK") {}

    function mint(address to) external {
        _mint(to, currentTokenId++);
    }
}
