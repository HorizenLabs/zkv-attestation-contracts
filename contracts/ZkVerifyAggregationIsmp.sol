// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "@polytope-labs/ismp-solidity/interfaces/IIsmpModule.sol";
import "@polytope-labs/ismp-solidity/interfaces/IIsmpHost.sol";
import "@polytope-labs/ismp-solidity/interfaces/Message.sol";
import "@polytope-labs/ismp-solidity/interfaces/IDispatcher.sol";
import "./IsmpGuest.sol";
import "./abstract/ZkVerifyAggregationBase.sol";
import {Bytes} from "@polytope-labs/solidity-merkle-trees/src/trie/Bytes.sol";

/**
 * @title ZkVerifyAggregationIsmp Contract
 * @notice It allows receiving (from Hyperbridge), persisting and verifying aggregation proofs coming from zkVerify chain.
 */
contract ZkVerifyAggregationIsmp is ZkVerifyAggregationBase, IsmpGuest, BaseIsmpModule {

    using Bytes for bytes;

    /// @notice State machine for source request
    bytes public constant STATE_MACHINE = bytes("SUBSTRATE-zkv_");

    // @notice Action is unauthorized
    error UnauthorizedAction();

    /**
     * @notice Construct a new ZkVerifyAggregationIsmp contract
     * @param _operator Operator for the contract
     * @param _operator Ismp host contract address
    */
    constructor(
        address _operator,
        address _ismpHost
    ) ZkVerifyAggregationBase(_operator) IsmpGuest(_ismpHost) {}

    function host() public view override returns (address) {
        return getHost();
    }

    /**
     * @notice Receive hyperbridge message containing an aggregation
     * @param incoming request from hyperbridge
     * @dev caller must be host address or risk critical vulnerabilies from unauthorized calls to this method by malicious actors.
    */
    function onAccept(IncomingPostRequest memory incoming) external override onlyHost {

        PostRequest memory request = incoming.request;
        if (!request.source.equals(STATE_MACHINE)) revert UnauthorizedAction();

        (uint256 _domainId, uint256 _aggregationId, bytes32 _proofsAggregation) = abi.decode(request.body, (uint256, uint256, bytes32));

        proofsAggregations[_domainId][_aggregationId] = _proofsAggregation;

        emit AggregationPosted(_domainId, _aggregationId, _proofsAggregation);
    }
}