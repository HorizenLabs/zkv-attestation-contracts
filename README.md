# zkv-attestation-contracts

## Installing

```shell
npm install
```

## Compiling

```shell
npx hardhat compile
```

## Testing

```shell
npx hardhat test
```

## Performing proof verification

The contracts inside `contracts/verifiers` can be used for performing proof verification via zkVerify.
A smart contract that needs to perform proof verification should inherit from the relevant smart contract inside `contracts/verifiers`.

The constructor of these contracts requires as input the address of the `zkVerifyAggregation` contract instance deployed on a supported EVM. The list of the supported chains, and the relevant addresses can be found [here](https://docs.zkverify.io/relevant_links).

Each of the contracts inside `contracts/verifiers` features a `verify` method, which takes as arguments:

- the _vk hash_,
- the _verifier version_ (for versioned verifiers only),
- the _public inputs_ of the proof,
- the _domain id_ (should be retrieved from zkVerify),
- the _aggregation id_ (should be retrieved from zkVerify),
- the _merkle path_ of the statement (should be retrieved from zkVerify),
- the _leaf count_ of the merkle tree (should be retrieved from zkVerify),
- the _index_ of the statement inside the merkle tree (should be retrieved from zkVerify)
