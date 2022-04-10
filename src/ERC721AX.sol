// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

error CallerNotOwnerNorApproved();
error MintToZeroAddress();
error MintZeroQuantity();
error MintExceedsLimit();
error MintExceedsMaxPerWallet();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error NonexistentToken();

// based on https://github.com/chiru-labs/ERC721A
// inspired by https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol

// caveats:
// collectionSize must be < type(uint128).max
abstract contract ERC721AX {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    struct TokenData {
        address owner;
        uint56 startTimestamp;
        bool nextTokenDataSet;
    }

    struct UserData {
        uint128 balance;
        uint128 numMinted;
    }

    uint256 private immutable _startingIndex;
    uint256 private immutable _collectionSize;
    uint256 private immutable _maxPerWallet;

    uint256 private _currentIndex;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => TokenData) private _tokenData;
    mapping(address => UserData) private _userData;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startingIndex_,
        uint256 collectionSize_,
        uint256 maxPerWallet_
    ) {
        _name = name_;
        _symbol = symbol_;

        _startingIndex = startingIndex_;
        _collectionSize = collectionSize_;
        _maxPerWallet = maxPerWallet_;

        _currentIndex = _startingIndex;
    }

    /* ------------- External ------------- */

    function approve(address to, uint256 tokenId) public {
        address owner = ERC721AX.ownerOf(tokenId);

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        unchecked {
            TokenData memory tokenData = _tokenDataOf(tokenId);

            if (tokenData.owner != from) revert TransferFromIncorrectOwner();

            bool isApprovedOrOwner = (msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                getApproved[tokenId] == msg.sender);

            if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
            if (to == address(0)) revert TransferToZeroAddress();

            delete getApproved[tokenId];

            --_userData[from].balance;
            ++_userData[to].balance;

            TokenData storage currSlot = _tokenData[tokenId];
            currSlot.owner = to;
            currSlot.startTimestamp = uint56(block.timestamp);
            currSlot.nextTokenDataSet = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenData storage nextSlot = _tokenData[nextTokenId];
            if (
                !tokenData.nextTokenDataSet &&
                nextSlot.owner == address(0) &&
                // && nextTokenId != _currentIndex
                nextTokenId < _startingIndex + _collectionSize // it's ok to check collectionSize instead of _currentIndex
            ) {
                // _tokenData[nextTokenId] = TokenData(from, tokenData.startTimestamp, false);
                nextSlot.owner = from;
                nextSlot.startTimestamp = tokenData.startTimestamp;
            }

            emit Transfer(from, to, tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        transferFrom(from, to, tokenId);
        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) !=
            IERC721Receiver(to).onERC721Received.selector
        ) revert TransferToNonERC721ReceiverImplementer();
    }

    /* ------------- View ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _currentIndex - _startingIndex;
    }

    function startingIndex() public view returns (uint256) {
        return _startingIndex;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _userData[owner].balance;
    }

    function numMinted(address owner) public view returns (uint256) {
        return _userData[owner].numMinted;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _tokenDataOf(tokenId).owner;
    }

    function _tokenDataOf(uint256 tokenId) internal view returns (TokenData memory) {
        unchecked {
            if (!_exists(tokenId)) revert NonexistentToken();

            for (uint256 curr = tokenId; ; --curr) {
                TokenData memory tokenData = _tokenData[curr];
                if (tokenData.owner != address(0)) return tokenData;
            }

            revert NonexistentToken();
        }
    }

    /* ------------- O(N) read-only ------------- */

    function tokenIdsOf(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 balance = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](balance);

            if (balance == 0) return tokenIds;

            uint256 endIndex = _currentIndex;
            uint256 count;

            for (uint256 i = _startingIndex; i < endIndex; ++i) {
                if (owner == ownerOf(i)) {
                    tokenIds[count++] = i;
                    if (balance == count) return tokenIds;
                }
            }

            return tokenIds;
        }
    }

    /* ------------- Internal ------------- */

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startingIndex <= tokenId && tokenId < _currentIndex;
    }

    function _mint(address to, uint256 quantity) internal {
        unchecked {
            if (to == address(0)) revert MintToZeroAddress();
            if (quantity == 0) revert MintZeroQuantity();

            uint256 startTokenId = _currentIndex;
            uint256 supply = startTokenId - _startingIndex; // assumption: _currentIndex >= _startingIndex

            // warning: overflows can happen, summing that this is guarded against by using maxPerTx or adding a price
            if (supply + quantity > _collectionSize) revert MintExceedsLimit();

            UserData memory userData = _userData[to];
            uint256 newBalance = userData.balance + quantity;
            uint256 newNumMinted = userData.numMinted + quantity;
            if (userData.numMinted + quantity > _maxPerWallet && to == msg.sender && address(this).code.length != 0)
                revert MintExceedsMaxPerWallet();

            _userData[to].balance = uint128(newBalance);
            _userData[to].numMinted = uint128(newNumMinted);

            _tokenData[startTokenId].owner = to;
            _tokenData[startTokenId].startTimestamp = uint56(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != end);

            _currentIndex = updatedIndex;
        }
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
