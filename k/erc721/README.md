# The Solidity-Compatible ERC721
The code in this directory aims at the creation of an [ERC721](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md) token that is fully Solidity compatible and exhibits identical behavior to a Solidity-based ERC721 token.

## Vyper Version
`0.1.0b6`

## Verification
We verified runtime bytecode compiled with this command.
```
vyper -f bytecode_runtime ERC721.vy 
```
