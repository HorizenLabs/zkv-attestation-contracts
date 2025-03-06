// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title ZkVerifyAggregationProxy
 * @notice A transparent proxy for the ZkVerifyAggregation contracts
 */
contract ZkVerifyAggregationProxy is ERC1967Proxy {
    /**
     * @notice Construct a new ZkVerifyAggregationProxy
     * @param _logic The address of the implementation contract
     * @param _data The encoded function call to initialize the proxy
     */
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}
}