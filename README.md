# verified-vyper-contracts
Formally Verified Vyper Contracts

## How to get started

* Check prerequisites of K framework.

https://github.com/kframework/k#prerequisites

* Clone repo and build:

```
git clone git@github.com:LayerXcom/verified-vyper-contracts.git
cd verified-vyper-contracts
make all
```

## Instruction

The formal specifications presented in this repository are written in [eDSL], a domain-specific language for EVM specifications.

#### Generating Full Reachability Logic Specifications

Run the following command in the root directory of this repository, and it will generate the full reachability logic specifications of a certain project, under the directory `specs`:

```
$ make <project>  // e.g. make erc20
```

#### Reproducing Proofs

To prove that the specifications are satisfied by (the compiled EVM bytecode of) the target contracts, run the EVM verifier as follows:

```
$ .build/evm-semantics/kevm prove specs/<project>/<target>-spec.k
```

where `<project>/<target>` is the target contract (or function) to verify.


## References
This project is based on K Framework and Runtime Verification's works. See [their resources](https://github.com/runtimeverification/verified-smart-contracts/blob/master/README.md#resources) for the details of KEVM and background knowledge.