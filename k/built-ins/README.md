# Vyper built-in functions
In this directory, we formally verify [Vyper's built-in functions](https://vyper.readthedocs.io/en/latest/built-in-functions.html).
This is a partial formal verification of the Vyper compiler.

## Vyper Version
`0.1.0b6`

## Verification
We verified runtime bytecode compiled with this command.
```
vyper -f bytecode_runtime Built-ins.vy
```