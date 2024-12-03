const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ZkVerifyAggregationIsmp contract", function () {
    let ZkVerifyAggregationIsmp;
    let verifierInstance;
    let mockFeeToken;
    let dispatcherContract;

    const initialAttestationId = 1n;

    let owner, operator, addr1, addr2, ismpHost, relayerAddress, addrs, dispatcherSigner;

    let operatorRole = ethers.solidityPackedKeccak256(["string"], ["OPERATOR"]);
    let ownerRole = ethers.encodeBytes32String("");

    let minSubstrateTree = {
        root: "0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6",
        leaves: [
            "0x0000000000000000000000000000000000000000000000000000000000000001",
        ],
        proofs: [],
    };

    let substrateTree = {
        root: "0xd2297c32eeb9a5378d85368ed029315498d1b40d9b03e9ad93bee97a382b47c8",
        leaves: [
            "0x0000000000000000000000000000000000000000000000000000000000000001",
            "0x0000000000000000000000000000000000000000000000000000000000000002",
            "0x0000000000000000000000000000000000000000000000000000000000000003",
            "0x0000000000000000000000000000000000000000000000000000000000000004",
            "0x0000000000000000000000000000000000000000000000000000000000000005",
            "0x0000000000000000000000000000000000000000000000000000000000000006",
            "0x0000000000000000000000000000000000000000000000000000000000000007",
        ],
        proofs: [
            [
                "0x405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace",
                "0x4a008209643838d588e1e3949a8a49c2dc4dfb50ee6aab985a7cf6eccba95084",
                "0xc7bd4d69c8648fe845b6e254ee355bdee759904dde840623da4d218300cb6e89",
            ],
            [
                "0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6",
                "0x4a008209643838d588e1e3949a8a49c2dc4dfb50ee6aab985a7cf6eccba95084",
                "0xc7bd4d69c8648fe845b6e254ee355bdee759904dde840623da4d218300cb6e89",
            ],
            [
                "0x8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b",
                "0x50387073e2d4f7060a3c02c3c5268d8a72700a28b5cbd7e23314ae0e1ebda895",
                "0xc7bd4d69c8648fe845b6e254ee355bdee759904dde840623da4d218300cb6e89",
            ],
            [
                "0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b",
                "0x50387073e2d4f7060a3c02c3c5268d8a72700a28b5cbd7e23314ae0e1ebda895",
                "0xc7bd4d69c8648fe845b6e254ee355bdee759904dde840623da4d218300cb6e89",
            ],
            [
                "0xf652222313e28459528d920b65115c16c04f3efc82aaedc97be59f3f377c0d3f",
                "0xa66cc928b5edb82af9bd49922954155ab7b0942694bea4ce44661d9a8736c688",
                "0x1e8cc8511a4954df48a80e5f5b8da3419a99ba3e7697574234e10893022167fc",
            ],
            [
                "0x036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db0",
                "0xa66cc928b5edb82af9bd49922954155ab7b0942694bea4ce44661d9a8736c688",
                "0x1e8cc8511a4954df48a80e5f5b8da3419a99ba3e7697574234e10893022167fc",
            ],
            [
                "0x75d78cae9ac952a6bdb1d50ff7497e0fc5986fff3e26261710f96f2e29ff6552",
                "0x1e8cc8511a4954df48a80e5f5b8da3419a99ba3e7697574234e10893022167fc",
            ],
        ],
    };

    let incomingPostRequest;

    /**
     * Construct a MerkleTree from the leaf nodes.
     */
    beforeEach(async function () {
        [owner, operator, addr1, addr2, ismpHost, relayerAddress, ...addrs] = await ethers.getSigners();
        ZkVerifyAggregationIsmp = await ethers.getContractFactory(
            "ZkVerifyAggregationIsmp"
        );

        // Deploy mock fee token
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        mockFeeToken = await ERC20Mock.deploy("Stable Mock", "sMock");
        await mockFeeToken.waitForDeployment();

        // Deploy minimal dispatcher with mock fee token
        const DispatcherMock = await ethers.getContractFactory("DispatcherMock");
        dispatcherContract = await DispatcherMock.deploy(await mockFeeToken.getAddress());
        await dispatcherContract.waitForDeployment();

        const dispatcherAddress = await dispatcherContract.getAddress();
        await network.provider.send("hardhat_setBalance", [
            dispatcherAddress,
            "0x1000000000000000000"  // Some ETH
        ]);

        // Impersonate the dispatcher account
        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [dispatcherAddress],
        });

        dispatcherSigner = await ethers.getSigner(dispatcherAddress);

        const stringToBytes = (str) => ethers.toUtf8Bytes(str);

        const encodedBody = ethers.AbiCoder.defaultAbiCoder().encode(
            ["uint256", "bytes32"],
            [initialAttestationId, substrateTree.root]
        );

        const postRequest = {
            source: stringToBytes("source_machine_123"),
            dest: stringToBytes("destination_machine_456"),
            nonce: 1234n,
            from: stringToBytes("module_from_789"),
            to: stringToBytes("module_to_101"),
            timeoutTimestamp: BigInt(Math.floor(Date.now() / 1000) + 3600), // 1 hour from now
            body: encodedBody
        };

        incomingPostRequest =  {
            request: postRequest,
            relayer: relayerAddress
        };

        /*************************************************************
         *    (WIP) Match as close as possible to expected MerkleTree data:
         *    bytes32 leaf = keccak256(abi.encodePacked(inputSnark, psId));
         *************************************************************/

        //deploy verifier
        verifierInstance = await ZkVerifyAggregationIsmp.deploy(await operator.getAddress(), await dispatcherContract.getAddress());
        await verifierInstance.waitForDeployment();
    });

    it("should initialize correct parameters", async function () {
        expect(
            await verifierInstance.hasRole(ownerRole, owner.getAddress())
        ).to.equal(true);
    });

    it("only owner can set operator", async function () {
        await verifierInstance
            .connect(owner)
            .revokeRole(operatorRole, operator.getAddress());
        await verifierInstance
            .connect(owner)
            .grantRole(operatorRole, addr1.getAddress());
        await expect(
            verifierInstance
                .connect(addr1)
                .grantRole(operatorRole, addr1.getAddress())
        ).to.be.revertedWith(
            "AccessControl: account " +
            (await addr1.getAddress()).toLowerCase() +
            " is missing role " +
            ownerRole
        );
    });

    /********************************
     *
     *    submitAttestation
     *
     ********************************/
    it("ismpHost can invoke onAccept", async function () {
        await verifierInstance
            .connect(dispatcherSigner)
            .onAccept(incomingPostRequest);
        await expect(
            await verifierInstance
                .connect(operator)
                .proofsAggregations(initialAttestationId)
        ).to.equal(substrateTree.root);
    });

    it("non-ismpHost cannot invoke onAccept", async function () {
        await expect(
            verifierInstance
                .connect(owner)
                .onAccept(incomingPostRequest)
        ).to.be.revertedWithCustomError(verifierInstance, "UnauthorizedCall");
    });

    it("operator can enable sequel aggregations", async function () {
        await verifierInstance
            .connect(operator)
            .flipIsEnforcingSequentialAggregations();
        await expect(
            await verifierInstance
                .connect(operator)
                .isEnforcingSequentialAggregations()
        ).to.equal(true);
    });

    it("non-operator cannot enable sequel aggregations", async function () {
        await expect(
            verifierInstance.connect(addr2).flipIsEnforcingSequentialAggregations()
        ).to.be.revertedWith(
            "AccessControl: account " +
            (await addr2.getAddress()).toLowerCase() +
            " is missing role 0x523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c"
        );
    });

    it("when sequencing is enabled, sequence enforced on onAccept", async function () {
        await verifierInstance
            .connect(operator)
            .flipIsEnforcingSequentialAggregations();

        /* Positive Case */
        await verifierInstance
            .connect(dispatcherSigner)
            .onAccept(incomingPostRequest);
        await expect(
            await verifierInstance
                .connect(operator)
                .proofsAggregations(initialAttestationId)
        ).to.equal(substrateTree.root);

        /* Negative Case */
        await expect(
            verifierInstance
                .connect(dispatcherSigner)
                .onAccept(incomingPostRequest)
        ).to.be.revertedWithCustomError(verifierInstance, "InvalidAggregation");
    });


    /********************************
     *
     *    verifyProofAggregation
     *
     ********************************/
    it("verifyProofAggregation returns true for each leaf in the tree", async function () {
        await verifierInstance
            .connect(dispatcherSigner)
            .onAccept(incomingPostRequest);
        await expect(
            await verifierInstance
                .connect(operator)
                .proofsAggregations(initialAttestationId)
        ).to.equal(substrateTree.root);

        for (let i = 0, j = 1; i < substrateTree.leaves.length; i++, j++) {
            let returnVal = await verifierInstance
                .connect(operator)
                .verifyProofAggregation(
                    initialAttestationId,
                    substrateTree.leaves[i],
                    substrateTree.proofs[i],
                    substrateTree.leaves.length,
                    i
                );
            expect(returnVal).to.equal(true);
        }
    });

    it("verifyProofAggregation returns false if leaf is not in path", async function () {
        await verifierInstance
            .connect(dispatcherSigner)
            .onAccept(incomingPostRequest);
        await expect(
            await verifierInstance
                .connect(operator)
                .proofsAggregations(initialAttestationId)
        ).to.equal(substrateTree.root);

        let leafIndex = 6;
        let merklePath = substrateTree.proofs[6];
        let mismatchLeafIndex = 0;

        let returnVal = await verifierInstance
            .connect(operator)
            .verifyProofAggregation(
                initialAttestationId,
                substrateTree.leaves[mismatchLeafIndex],
                merklePath,
                substrateTree.leaves.length,
                leafIndex
            );

        expect(returnVal).to.equal(false);
    });

    it("verifyProofAggregation returns false if leafIndex is out of bounds", async function () {
        await verifierInstance
            .connect(dispatcherSigner)
            .onAccept(incomingPostRequest);
        await expect(
            await verifierInstance
                .connect(operator)
                .proofsAggregations(initialAttestationId)
        ).to.equal(substrateTree.root);

        let outOfBoundsLeafIndex = 8;
        let merklePath = substrateTree.proofs[0];
        await expect(
            verifierInstance
                .connect(operator)
                .verifyProofAggregation(
                    initialAttestationId,
                    substrateTree.leaves[0],
                    merklePath,
                    substrateTree.leaves.length,
                    outOfBoundsLeafIndex
                )
        ).to.be.revertedWithCustomError(verifierInstance, "IndexOutOfBounds");
    });

    it("verifyProofAggregation returns true if only one leaf and leaf matches root", async function () {
        const _encodedBody = ethers.AbiCoder.defaultAbiCoder().encode(
            ["uint256", "bytes32"],
            [initialAttestationId, minSubstrateTree.root]
        );

        incomingPostRequest.request.body = _encodedBody;

        await verifierInstance
            .connect(dispatcherSigner)
            .onAccept(incomingPostRequest);
        await expect(
            await verifierInstance
                .connect(operator)
                .proofsAggregations(initialAttestationId)
        ).to.equal(minSubstrateTree.root);

        let returnVal = await verifierInstance
            .connect(operator)
            .verifyProofAggregation(
                initialAttestationId,
                minSubstrateTree.leaves[0],
                minSubstrateTree.proofs,
                minSubstrateTree.leaves.length,
                0
            );

        expect(returnVal).to.equal(true);
    });
});
