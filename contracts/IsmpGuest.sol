// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

contract IsmpGuest {
    address private _host;

    constructor(address _ismpHost) {
        _host = _ismpHost;
    }

    function getHost() public view returns (address) {
        return _host;
    }
}