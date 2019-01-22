# FVyper
[![CircleCI](https://circleci.com/gh/LayerXcom/verified-vyper-contracts.svg?style=svg)](https://circleci.com/gh/LayerXcom/verified-vyper-contracts)  
A collection of useful Vyper contracts developed with formal methods  

WARNING: These contracts are not audited and formal verification is WIP. Take care when you use them for production.

## Directory structure
The `/contracts` directory contains vyper contracts we use in formal verification (`/k` directory) and unit testing ( `/tests` directory).

The `/k` directory contains files to do formal verification with [K Framework](https://github.com/kframework/k).

The `/tests` directory contains unit tests.

## Progress
See [roadmap](https://github.com/LayerXcom/verified-vyper-contracts/issues/5).  

## References
This project is based on K Framework and Runtime Verification's works. See [their resources](https://github.com/runtimeverification/verified-smart-contracts/blob/master/README.md#resources) for the details of KEVM and background knowledge.

## Acknowledgements  
FVyper is supported by KEVM and Vyper teams. We’d like to express thanks to them and their great work.  
