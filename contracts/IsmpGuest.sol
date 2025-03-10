// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract IsmpGuest  is Initializable {
    address private _host;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the IsmpGuest contract
     * @param _ismpHost The address of the ISMP host
     */
    function __IsmpGuest_init(address _ismpHost) internal onlyInitializing {
        _host = _ismpHost;
    }

    function getHost() public view returns (address) {
        return _host;
    }
}