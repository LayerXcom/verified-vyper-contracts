## How to get started

You need to install dependencies of K. See [prerequisites](https://github.com/kframework/k#prerequisites).

Then

```
make all
```

### Modification in eDSL
Current eDSL defined in [edsl.md](https://github.com/kframework/evm-semantics/blob/9a409babcd9b77a0f9a30f52350e4c5d46e6b086/edsl.md) and [data.md](https://github.com/kframework/evm-semantics/blob/9a409babcd9b77a0f9a30f52350e4c5d46e6b086/data.md) is not correct or enough so we need to modify them as follows. These things would be fixed and added in the original repository.

#### hashedLocation
`#hashedLocation` rule is not correct for the latest Vyper storage layout. Therefore, you need to modify that rule in `.build/evm-semantics/.build/java/edsl.k` (line 303) manually as follows: 
```
rule #hashedLocation("Vyper", BASE, OFFSET OFFSETS) => #hashedLocation("Vyper", keccakIntList(BASE OFFSET), OFFSETS)
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
