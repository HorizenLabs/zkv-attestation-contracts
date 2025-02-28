// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.20;

import "../interfaces/IVerifyProofAggregation.sol";

struct Args {
    uint256 domainId;
    uint256 aggregationId;
    bytes32 leaf;
    bytes32[] merklePath;
    uint256 leafCount;
    uint256 index;
}

contract VerifyProofAggregationMock is IVerifyProofAggregation {
    uint256 domainId;
    uint256 aggregationId;
    bytes32 leaf;
    bytes32[] merklePath;
    uint256 leafCount;
    uint256 index;

    function verifyProofAggregation(
        uint256 _domainId,
        uint256 _aggregationId,
        bytes32 _leaf,
        bytes32[] calldata _merklePath,
        uint256 _leafCount,
        uint256 _index
    ) external view returns (bool) {
        require(_domainId == domainId, "domainId mismatch");
        require(_aggregationId == aggregationId, "aggregationId mismatch");
        require(_leaf == leaf, "aggregationId mismatch");
        require(_merklePath.length == merklePath.length, "merklePath length mismatch");
        for (uint256 i = 0; i != _merklePath.length; i++) {
            require(_merklePath[i] == merklePath[i], "merklePath mismatch");
        }
        require(_leafCount == leafCount, "leafCount mismatch");
        require(_index == index, "index mismatch");
        return true;
    }

    function setExpectedArgs(Args calldata args) public {
        domainId = args.domainId;
        aggregationId = args.aggregationId;
        leaf = args.leaf;
        delete merklePath;
        for (uint256 i = 0; i != args.merklePath.length; i++) {
            merklePath.push(args.merklePath[i]);
        }
        leafCount = args.leafCount;
        index = args.index;
    }
}
