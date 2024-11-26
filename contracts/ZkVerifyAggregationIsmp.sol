// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "@polytope-labs/ismp-solidity/interfaces/IIsmpModule.sol";
import "@polytope-labs/ismp-solidity/interfaces/IIsmpHost.sol";
import "@polytope-labs/ismp-solidity/interfaces/Message.sol";
import "@polytope-labs/ismp-solidity/interfaces/IDispatcher.sol";
import "./interfaces/IZkVerifyAggregation.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./lib/Merkle.sol";

/**
 * @title ZkVerifyAggregationIsmp Contract
 * @notice It allows receiving (from Hyperbridge), persisting and verifying aggregation proofs coming from zkVerify chain.
 */
contract ZkVerifyAggregationIsmp is IZkVerifyAggregation, AccessControl, BaseIsmpModule {

    // IIsmpHost Address
    address private _host;

    /// @dev Role required for operator to submit/verify proofs.
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    /// @notice Latest valid aggregationId for bridge events.
    uint256 public latestAggregationId;

    /// @notice Mapping of MC aggregationIds to proofsAggregations.
    mapping(uint256 => bytes32) public proofsAggregations;

    bool public isEnforcingSequentialAggregations;

    /// @notice Emitted when a new aggregation is posted.
    /// @param _aggregationId Event aggregationId.
    /// @param _proofsAggregation Aggregated proofs.
    event AggregationPosted(uint256 indexed _aggregationId, bytes32 indexed _proofsAggregation);

    /// @notice Posted _aggregation must be sequential.
    error InvalidAggregation();

    /// @notice Prevent owner from handing over ownership
    error OwnerCannotRenounce();

    /**
     * @notice Construct a new ZkVerifyAggregationIsmp contract
     * @param _operator Operator for the contract
     * @param _operator Ismp host contract address
    */
    constructor(
        address _operator,
        address _ismpHost
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // it is used as owner
        _grantRole(OPERATOR, _operator);
        _host = _ismpHost;
    }

    /**
     * @notice Verify a proof against a stored merkle tree
     * @param _aggregationId the id of the aggregation from the Horizen main chain
     * @param _leaf of the merkle tree
     * @param _merklePath path from leaf to root of the merkle tree
     * @param _leafCount the number of leaves in the merkle tree
     * @param _index the 0 indexed `index`'th leaf from the bottom left of the tree, see test cases.
     * @dev caller must have the OPERATOR role, admin can add caller via AccessControl.grantRole()
    */
    function verifyProofAggregation(
        uint256 _aggregationId,
        bytes32 _leaf,
        bytes32[] calldata _merklePath,
        uint256 _leafCount,
        uint256 _index
    ) external view returns (bool) {

        // AggregationId must have already been posted.
        if (_aggregationId > latestAggregationId) {
            return false;
        }

        // Load the proofsAggregation at the given index from storage.
        bytes32 proofsAggregation = proofsAggregations[_aggregationId];

        // Verify the proofsAggregations/path.
        return Merkle.verifyProofKeccak(proofsAggregation, _merklePath, _leafCount, _index, _leaf);
    }

    /**
     * @notice Flip sequential enforcement for onAccept()
    * @dev caller must have the OPERATOR role
    */
    function flipIsEnforcingSequentialAggregations() external onlyRole(OPERATOR) {
        isEnforcingSequentialAggregations = !isEnforcingSequentialAggregations;
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

    function host() public view override returns (address) {
        return _host;
    }

    /**
     * @notice Receive hyperbridge message containing an aggregation
     * @param incoming request from hyperbridge
     * @dev caller must be host address or risk critical vulnerabilies from unauthorized calls to this method by malicious actors.
    */
    function onAccept(IncomingPostRequest memory incoming) external override onlyHost {

        (uint256 _aggregationId, bytes32 _proofsAggregation) = abi.decode(incoming.request.body, (uint256, bytes32));

        // Optionally, check that the new _aggregationId is sequential.
        if(isEnforcingSequentialAggregations && (_aggregationId != latestAggregationId + 1)) {
            revert InvalidAggregation();
        }

        latestAggregationId = _aggregationId;
        proofsAggregations[_aggregationId] = _proofsAggregation;

        emit AggregationPosted(_aggregationId, _proofsAggregation);
    }
}