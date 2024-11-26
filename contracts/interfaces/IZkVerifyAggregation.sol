// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

/**
 * @dev Define interface Horizen verifier
 */
interface IZkVerifyAggregation {

    function verifyProofAggregation(
        uint256 _aggregationId,
        bytes32 _leaf,
        bytes32[] calldata _merklePath,
        uint256 _leafCount,
        uint256 _index) external returns (bool);
}