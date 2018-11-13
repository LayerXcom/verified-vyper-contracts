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

The formal specifications presented in this repository are written in [eDSL](https://github.com/runtimeverification/verified-smart-contracts/blob/master/resources/edsl.md), a domain-specific language for EVM specifications.

#### Generating Full Reachability Logic Specifications

Run the following command in the root directory of this repository, and it will generate the full reachability logic specifications of a certain project, under the directory `specs`:

```
$ make <project>  // e.g. make erc20
```

#### Reproducing Proofs

To prove that the specifications are satisfied by (the compiled EVM bytecode of) the target contracts, run the EVM verifier as follows:

```
$ make specs/<project>/<target>-spec.k.test // e.g. make specs/erc20/allowance-spec.k.test
```

where `<project>/<target>` is the target contract (or function) to verify.

This project is using WIP K version and you can use the options described [here](https://github.com/runtimeverification/verified-smart-contracts/blob/master/resources/kprove-tutorial.md#kprove-logging-options).

NOTE: The above command executes the following command:
```
.build/k/k-distribution/target/release/k/bin/kprove -v -d .build/evm-semantics/.build/java -m VERIFICATION --z3-executable --z3-impl-timeout 500 specs/<project>/<target>-spec.k
```

#### Modifying `hashedLocation`
Fow now, `#hashedLocation` rule in [edsl.md](https://github.com/kframework/evm-semantics/blob/e6c4b961495768a429fcffaa81418472953c8568/edsl.md#hashed-location-for-storage) of KEVM is not correct for the latest Vyper storage layout. Therefore, you need to modify that manually as follows: 
```
rule #hashedLocation("Vyper", BASE, OFFSET OFFSETS) => #hashedLocation("Vyper", keccakIntList(BASE OFFSET), OFFSETS)
```

## References
This project is based on K Framework and Runtime Verification's works. See [their resources](https://github.com/runtimeverification/verified-smart-contracts/blob/master/README.md#resources) for the details of KEVM and background knowledge.