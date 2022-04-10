// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721AX} from "../ERC721AX.sol";

error MintExceedsMaxPerTx();

contract MockERC721AX is ERC721AX {
    uint256 constant maxPerTx = 100;

    constructor(
        string memory name,
        string memory symbol,
        uint256 startingIndex_,
        uint256 collectionSize_,
        uint256 maxPerWallet_
    ) ERC721AX(name, symbol, startingIndex_, collectionSize_, maxPerWallet_) {}

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }

    function mint(address user, uint256 quantity) external {
        // if (quantity > maxPerTx) revert MintExceedsMaxPerTx();
        _mint(user, quantity);
    }

    function mintOne(address user) external {
        _mint(user, 1);
    }

    function mintFive(address user) external {
        _mint(user, 5);
    }
}
