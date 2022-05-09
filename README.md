# ERC721AX

Bridging the optimality-gap in [ERC721A](https://github.com/chiru-labs/ERC721A) in a realistic minting setup.

- Internally, `tokenData` is passed as storage instead of memory.
- Keeps track of whether the next token data has already been set before, so that we don't have to check it (1 cold sload) on every transfer for all eternity.
- Saves (warm) sload on variables such as `collectionSize` and `maxPerWallet`.

Further optimization could be achieved by storing the number of minted nfts in a certain batch and then back-calculating if a certain tokenId is the last in the batch. I.e. if A mints 5 ids, `A 0 0 0 0` is stored. Now, if we transfer the last id in the batch, we know that the token following that one will have to be explicitly set, so we can skip an sload check.

| Function                      |    Gas |
| :---------------------------- | -----: |
| test_mint1_ERC721A()          |  59669 |
| test_mint1_ERC721AX()         |  59355 |
| test_mint5_ERC721A()          |  67508 |
| test_mint5_ERC721AX()         |  67164 |
| test_transferFrom1_ERC721A()  |  53562 |
| test_transferFrom1_ERC721AX() |  49402 |
| test_transferFrom2_ERC721A()  |  73843 |
| test_transferFrom2_ERC721AX() |  72324 |
| test_transferFrom3_ERC721A()  | 121225 |
| test_transferFrom3_ERC721AX() | 108486 |

`test_transferFrom2` is when the optimization regarding `nextTokenDataSet` is not in effect.

[Gas snapshot](.gas-snapshot)

```
forge snapshot --match-contract GasTest
```
