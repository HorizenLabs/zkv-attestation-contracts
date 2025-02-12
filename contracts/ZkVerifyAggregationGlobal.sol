// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "./ZkVerifyAggregationIsmp.sol";
import "./ZkVerifyAggregation.sol";

/**
 * @title ZkVerifyAggregationGlobal Contract
 * @notice It allows submitting and verifying aggregation proofs coming from zkVerify chain for both versions Ismp and Non Ismp one.
 */
contract ZkVerifyAggregationGlobal is ZkVerifyAggregation, ZkVerifyAggregationIsmp {

    constructor(address _operator, address _ismpHost) ZkVerifyAggregation(_operator) ZkVerifyAggregationIsmp(_ismpHost) {}
}