// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "./abstract/ZkVerifyAggregationBase.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./lib/Merkle.sol";

/**
 * @title ZkVerifyAggregation Contract
 * @notice It allows submitting and verifying aggregation proofs coming from zkVerify chain.
 */
contract ZkVerifyAggregation is AccessControl, ZkVerifyAggregationBase {

   /// @dev Role required for operator to submit/verify proofs.
   bytes32 public constant OPERATOR = keccak256("OPERATOR");

   /// @notice Batch submissions must have an equal number of ids to proof aggregations.
   error InvalidBatchCounts();

   /// @notice Prevent owner from handing over ownership
   error OwnerCannotRenounce();

   /**
    * @notice Construct a new NewHorizenProofVerifier contract
    * @param _operator Operator for the contract
    */
   constructor(address _operator) {
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // it is used as owner
      _grantRole(OPERATOR, _operator);
   }

   /**
    * @notice Submit Aggregation
    * @param _domainId the id of the domain
    * @param _aggregationId the id of the aggregation from the NewHorizen Relayer
    * @param _proofsAggregation aggregation of a set of proofs
    * @dev caller must have the OPERATOR role, admin can add caller via AccessControl.grantRole()
    */
   function submitAggregation(
      uint256 _domainId,
      uint256 _aggregationId,
      bytes32 _proofsAggregation
   ) external onlyRole(OPERATOR) {
      _registerAggregation(_domainId, _aggregationId, _proofsAggregation);
   }

   /**
    * @notice Submit a Batch of aggregations, for a given domain Id, useful if a relayer needs to catch up.
    * @param _domainId id of domain
    * @param _aggregationIds ids of aggregations from the NewHorizen Relayer
    * @param _proofsAggregations a set of proofs
    * @dev caller must have the OPERATOR role, admin can add caller via AccessControl.grantRole()
    */
   function submitAggregationBatchByDomainId(
      uint256 _domainId,
      uint256[] calldata _aggregationIds,
      bytes32[] calldata _proofsAggregations
   ) external onlyRole(OPERATOR) {

      if(_aggregationIds.length != _proofsAggregations.length) {
         revert InvalidBatchCounts();
      }

      for (uint256 i; i < _aggregationIds.length;) {
         _registerAggregation(_domainId, _aggregationIds[i], _proofsAggregations[i]);
         unchecked {
            ++i;
         }
      }
   }
}