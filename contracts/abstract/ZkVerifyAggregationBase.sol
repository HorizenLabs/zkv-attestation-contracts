// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../lib/Merkle.sol";

abstract contract ZkVerifyAggregationBase is AccessControl {

    /// @dev Role required for operator to submit/verify proofs.
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    /// @notice Mapping of domain Ids to aggregationIds to proofsAggregations.
    mapping(uint256 => mapping(uint256 => bytes32)) public proofsAggregations;

    /// @notice Emitted when a new aggregation is posted.
    /// @param _domainId Event domainId.
    /// @param _aggregationId Event aggregationId.
    /// @param _proofsAggregation Aggregated proofs.
    event AggregationPosted(uint256 indexed _domainId, uint256 indexed _aggregationId, bytes32 indexed _proofsAggregation);

    /// @notice Prevent owner from handing over ownership
    error OwnerCannotRenounce();

    /**
    * @notice Construct a new NewHorizenProofVerifier contract
    * @param _operator Operator for the contract
    */
    constructor(
        address _operator
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // it is used as owner
        _grantRole(OPERATOR, _operator);
    }

    /**
     * @notice Verify a proof against a stored merkle tree
     * @param _domainId the id of the domain from the Horizen main chain
     * @param _aggregationId the id of the aggregation from the Horizen main chain
     * @param _leaf of the merkle tree
     * @param _merklePath path from leaf to root of the merkle tree
     * @param _leafCount the number of leaves in the merkle tree
     * @param _index the 0 indexed `index`'th leaf from the bottom left of the tree, see test cases.
     * @dev caller must have the OPERATOR role, admin can add caller via AccessControl.grantRole()
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


    /**
    * @notice prohibits owner to renounce its role with this override
    */
    function renounceRole(bytes32 role, address account) public override {
        if(role == DEFAULT_ADMIN_ROLE) {
            revert OwnerCannotRenounce();
        }
        super.renounceRole(role, account);
    }

}