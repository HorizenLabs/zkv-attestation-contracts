// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "./abstract/ZkVerifyAggregationBase.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./lib/Merkle.sol";

/**
 * @title ZkVerifyAggregation Contract
 * @notice It allows submitting and verifying aggregation proofs coming from zkVerify chain.
 */
contract ZkVerifyAggregation is Initializable, AccessControlUpgradeable, UUPSUpgradeable, ZkVerifyAggregationBase {

   /// @dev Role required for operator to submit/verify proofs.
   bytes32 public constant OPERATOR = keccak256("OPERATOR");

   /// @dev Role that allows upgrading the implementation
   bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

   /// @notice Batch submissions must have an equal number of ids to proof aggregations.
   error InvalidBatchCounts();

   /// @custom:oz-upgrades-unsafe-allow constructor
   constructor() {
      _disableInitializers();
   }

   /**
    * @notice Initialize the contract (replaces constructor)
    * @param _operator Operator for the contract
    * @param _upgrader Upgrader address for the contract
    */
   function initialize(address _operator, address _upgrader) public initializer {
      __ZkVerifyAggregation_init(_operator, _upgrader);
   }

   /**
    * @notice Initialize the contract (replaces constructor)
    * @param _operator Operator for the contract
    * @param _upgrader Upgrader address for the contract
    */
   function __ZkVerifyAggregation_init(address _operator, address _upgrader) internal onlyInitializing {
      __AccessControl_init();
      __UUPSUpgradeable_init();

      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // it is used as owner
      _grantRole(OPERATOR, _operator);
      _grantRole(UPGRADER_ROLE, _upgrader);
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

   /**
    * @notice Function that allows the contract to be upgraded
    * @dev Only accounts with the UPGRADER_ROLE can call this function
    */
   function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}