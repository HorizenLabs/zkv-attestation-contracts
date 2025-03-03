// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IVerifyProofAggregation.sol";

contract ZkVerifyGroth16 {
    IVerifyProofAggregation immutable zkVerifyAggregation;

    bytes32 constant PROVING_SYSTEM_ID = keccak256(abi.encodePacked("groth16"));

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
        uint256 numInputs = inputs.length;
        bytes32[] memory encodedInputs = new bytes32[](numInputs);
        for (uint256 i = 0; i != numInputs; i++) {
            encodedInputs[i] = _changeEndianess(inputs[i]);
        }
        return abi.encodePacked(encodedInputs);
    }

    function _changeEndianess(uint256 input) internal pure returns (bytes32 out) {
        out = bytes32(input);
        // swap bytes
        out = ((out & 0xff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00) >> 8)
            | ((out & 0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff) << 8);
        // swap 2-byte long pairs
        out = ((out & 0xffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000) >> 16)
            | ((out & 0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff) << 16);
        // swap 4-byte long pairs
        out = ((out & 0xffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000) >> 32)
            | ((out & 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff) << 32);
        // swap 8-byte long pairs
        out = ((out & 0xffffffffffffffff0000000000000000ffffffffffffffff0000000000000000) >> 64)
            | ((out & 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff) << 64);
        // swap 16-byte long pairs
        out = (out >> 128) | (out << 128);
    }
}
