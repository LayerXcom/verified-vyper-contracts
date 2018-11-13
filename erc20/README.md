# The Solidity-Compatible ERC20
The code in this directory aims at the creation of an [ERC20](https://github.com/ethereum/EIPs/issues/20) token that is fully Solidity compatible and exhibits identical behavior to a Solidity-based ERC20 token.

The code is based on [the test contracts](https://github.com/Uniswap/contracts-vyper/blob/master/contracts/test_contracts/ERC20.vy) in Uniswap project.

## Vyper Version
`0.1.0b4`

## Verification
We verified runtime bytecode compiled with this command.
```
vyper -f bytecode_runtime ERC20.vy 
```