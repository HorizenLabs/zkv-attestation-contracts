// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

import "@polytope-labs/ismp-solidity/interfaces/IDispatcher.sol";

contract DispatcherMock is IDispatcher {

    address private immutable _feeToken;

    constructor(address feeTokenAddress) {
        _feeToken = feeTokenAddress;
    }

    function feeToken() external view returns (address) {
        return _feeToken;
    }

    function host() external pure returns (bytes memory) {
        return "";
    }

    function uniswapV2Router() external pure returns (address) {
        return address(0);
    }

    function nonce() external pure returns (uint256) {
        return 0;
    }

    function perByteFee(bytes memory) external pure returns (uint256) {
        return 0;
    }

    function dispatch(DispatchPost memory) external payable returns (bytes32) {
        return bytes32(0);
    }

    function dispatch(DispatchGet memory) external payable returns (bytes32) {
        return bytes32(0);
    }

    function dispatch(DispatchPostResponse memory) external payable returns (bytes32) {
        return bytes32(0);
    }

    function fundRequest(bytes32, uint256) external payable {}
    function fundResponse(bytes32, uint256) external payable {}
}