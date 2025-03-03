// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IVerifyProofAggregation.sol";

contract ZkVerifyUltraplonk {
    IVerifyProofAggregation immutable zkVerifyAggregation;

    bytes32 constant PROVING_SYSTEM_ID = keccak256(abi.encodePacked("ultraplonk"));

    constructor(address _zkVerifyAggregation) {
        zkVerifyAggregation = IVerifyProofAggregation(_zkVerifyAggregation);
    }

    function verify(
        bytes32 _vkHash,
        uint256[] memory _inputs,
        uint256 _domainId,
        uint256 _aggregationId,
        bytes32[] calldata _merklePath,
        uint256 _leafCount,
        uint256 _index
    ) public view returns (bool) {
        bytes32 leaf = statementHash(_vkHash, _inputs);
        return
            zkVerifyAggregation.verifyProofAggregation(_domainId, _aggregationId, leaf, _merklePath, _leafCount, _index);
    }

    function statementHash(bytes32 vkHash, uint256[] memory inputs) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(PROVING_SYSTEM_ID, vkHash, keccak256(encodePublicInputs(inputs))));
    }

    function encodePublicInputs(uint256[] memory inputs) public pure returns (bytes memory) {
        return abi.encodePacked(inputs);
    }
}
