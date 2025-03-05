// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IVerifyProofAggregation.sol";

contract ZkVerifyRisc0 {
    IVerifyProofAggregation immutable zkVerifyAggregation;

    bytes32 constant PROVING_SYSTEM_ID = keccak256(abi.encodePacked("risc0"));

    /**
     * @notice Construct a ZkVerifyRisc0 contract
     * @param _zkVerifyAggregation the address of the zkVerifyAggregation contract instance
     */
    constructor(address _zkVerifyAggregation) {
        zkVerifyAggregation = IVerifyProofAggregation(_zkVerifyAggregation);
    }

    /**
     * @notice Verify a Risc0 proof submitted to ZkVerify chain
     * @param _vkHash the hash of the verification key
     * @param _inputs the public inputs, as found in the risc0 journal
     * @param _version the verifier version (e.g. "risc0:v1.1")
     * @param _domainId the id of the domain (from zkVerify chain)
     * @param _aggregationId the id of the aggregation (from zkVerify chain)
     * @param _merklePath path from leaf to root of the merkle tree (from zkVerify chain)
     * @param _leafCount the number of leaves in the merkle tree (from zkVerify chain)
     * @param _index the index of the proof inside the merkle tree (from zkVerify chain)
     * @return bool the result of the verification
     */
    function verify(
        bytes32 _vkHash,
        string memory _version,
        bytes memory _inputs,
        uint256 _domainId,
        uint256 _aggregationId,
        bytes32[] calldata _merklePath,
        uint256 _leafCount,
        uint256 _index
    ) public view returns (bool) {
        bytes32 leaf = statementHash(_vkHash, _version, _inputs);
        return
            zkVerifyAggregation.verifyProofAggregation(_domainId, _aggregationId, leaf, _merklePath, _leafCount, _index);
    }

    /**
     * @notice Compute the statement hash associated to a Risc0 proof
     * @param vk the hash of the verification key
     * @param version the verifier version (e.g. "risc0:v1.1")
     * @param inputs the public inputs, as found in the risc0 journal
     * @return bytes32 the statement hash
     */
    function statementHash(bytes32 vk, string memory version, bytes memory inputs) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(PROVING_SYSTEM_ID, vk, sha256(bytes(version)), keccak256(inputs)));
    }
}
