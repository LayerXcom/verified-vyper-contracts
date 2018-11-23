# The Solidity-Compatible ERC20
The code in this directory aims at the creation of an [ERC20](https://github.com/ethereum/EIPs/blob/617ab2d0c34e0918aa712e363bae5ca3935f74f2/EIPS/eip-20.md) token that is fully Solidity compatible and exhibits identical behavior to a Solidity-based ERC20 token.

The code is based on [the test contracts](https://github.com/Uniswap/contracts-vyper/blob/754d7ffedfa653de1a5693655047e385cbbf66ab/contracts/test_contracts/ERC20.vy) in Uniswap project.

## Vyper Version
`0.1.0b4`

## Verification
We verified runtime bytecode compiled with this command.
```
vyper -f bytecode_runtime ERC20.vy 
```