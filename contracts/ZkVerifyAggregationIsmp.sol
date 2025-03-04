// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "@polytope-labs/ismp-solidity/interfaces/IIsmpModule.sol";
import "@polytope-labs/ismp-solidity/interfaces/IIsmpHost.sol";
import "@polytope-labs/ismp-solidity/interfaces/Message.sol";
import "@polytope-labs/ismp-solidity/interfaces/IDispatcher.sol";
import "./IsmpGuest.sol";
import "./abstract/ZkVerifyAggregationBase.sol";
import {Bytes} from "@polytope-labs/solidity-merkle-trees/src/trie/Bytes.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title ZkVerifyAggregationIsmp Contract
 * @notice It allows receiving (from Hyperbridge), persisting and verifying aggregation proofs coming from zkVerify chain.
 */
contract ZkVerifyAggregationIsmp is ZkVerifyAggregationBase, Initializable, AccessControlUpgradeable, UUPSUpgradeable, IsmpGuest, BaseIsmpModule {

    using Bytes for bytes;

    /// @notice State machine for source request
    bytes public constant STATE_MACHINE = bytes("SUBSTRATE-zkv_");

    // @notice Action is unauthorized
    error UnauthorizedAction();

    /// @dev Role that allows upgrading the implementation
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract (replaces constructor)
     * @param _ismpHost Ismp host contract address
     * @param _upgrader Upgrader address for the contract
     */
    function initialize(address _ismpHost, address _upgrader) public initializer {
        __ZkVerifyAggregationIsmp_init(_ismpHost, _upgrader);
    }

    /**
     * @notice Initialize the ISMP base
     * @param _ismpHost Ismp host contract address
     * @param _upgrader Upgrader address for the contract
     */
    function __ZkVerifyAggregationIsmp_init(address _ismpHost, address _upgrader) internal onlyInitializing {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __IsmpGuest_init(_ismpHost);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, _upgrader);
    }

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

        _registerAggregation(_domainId, _aggregationId, _proofsAggregation);
    }

    /**
     * @notice Function that allows the contract to be upgraded
     * @dev Only accounts with the UPGRADER_ROLE can call this function
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}