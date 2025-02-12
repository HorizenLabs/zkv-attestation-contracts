// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "../lib/Merkle.sol";

abstract contract ZkVerifyAggregationBase {

    /// @notice Mapping of domain Ids to aggregationIds to proofsAggregations.
    mapping(uint256 => mapping(uint256 => bytes32)) public proofsAggregations;

    /// @notice Emitted when a new aggregation is posted.
    /// @param _domainId Event domainId.
    /// @param _aggregationId Event aggregationId.
    /// @param _proofsAggregation Aggregated proofs.
    event AggregationPosted(uint256 indexed _domainId, uint256 indexed _aggregationId, bytes32 indexed _proofsAggregation);

    /**
    * @notice Construct a new ZkVerifyAggregationBase contract
    */
    constructor() {}

    /**
     * @notice Verify a proof against a stored merkle tree
     * @param _domainId the id of the domain from the Horizen main chain
     * @param _aggregationId the id of the aggregation from the Horizen main chain
     * @param _leaf of the merkle tree
     * @param _merklePath path from leaf to root of the merkle tree
     * @param _leafCount the number of leaves in the merkle tree
     * @param _index the 0 indexed `index`'th leaf from the bottom left of the tree, see test cases.
    */
    function verifyProofAggregation(
        uint256 _domainId,
        uint256 _aggregationId,
        bytes32 _leaf,
        bytes32[] calldata _merklePath,
        uint256 _leafCount,
        uint256 _index
    ) external view returns (bool) {
        // Load the proofsAggregation at the given domain Id and aggregationId.
        bytes32 proofsAggregation = proofsAggregations[_domainId][_aggregationId];

        // Verify the proofsAggregations/path.
        return Merkle.verifyProofKeccak(proofsAggregation, _merklePath, _leafCount, _index, _leaf);
    }

    function _registerAggregation(
        uint256 _domainId,
        uint256 _aggregationId,
        bytes32 _proofsAggregation
    ) internal {
        proofsAggregations[_domainId][_aggregationId] = _proofsAggregation;

        emit AggregationPosted(_domainId, _aggregationId, _proofsAggregation);
    }
}