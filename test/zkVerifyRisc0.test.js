const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ZkVerifyRisc0 contract", function () {
    let zkVerifyRisc0;
    let verifyProofAggregationMock;

    function validStatementV1_0() {
        return {
            vk: "0x32e1a33f3988c3cdf127e709cc0323a258b28df750b7a2d5ddc4c5e37f007d99",
            version: "risc0:v1.0",
            input: "0x01000078",
            leaf: "0x76082d85afb6dd62d982e672365143d9eee6e2640e60ef75e5cd1911748b4c1c",
        }
    };

    function validStatementV1_1() {
        return {
            vk: "0x2addbbeb4ddb2f2ec2b4a0a8a21c03f7d3bf42cfd2ee9f4a69d2ebd9974218b6",
            version: "risc0:v1.1",
            input: "0x8105000000000000",
            leaf: "0x1478ead484979edb8644274b3a0435b10bed35e0e5e0d1efa2732af3ac6e666c",
        }
    };

    beforeEach(async function () {
        VerifyProofAggregationMock = await ethers.getContractFactory("VerifyProofAggregationMock");
        ZkVerifyRisc0 = await ethers.getContractFactory("ZkVerifyRisc0");

        verifyProofAggregationMock = await VerifyProofAggregationMock.deploy();
        await verifyProofAggregationMock.waitForDeployment();
        zkVerifyRisc0 = await ZkVerifyRisc0.deploy(verifyProofAggregationMock.getAddress());
        await zkVerifyRisc0.waitForDeployment();
    });

    describe("statementHash", function () {
        it("returns expected result for v1.0", async function () {
            const { vk, version, input, leaf } = validStatementV1_0();
            await expect(
                await zkVerifyRisc0.statementHash(vk, version, input)
            ).to.be.equal(leaf);
        });
        it("returns expected result for v1.1", async function () {
            const { vk, version, input, leaf } = validStatementV1_1();
            await expect(
                await zkVerifyRisc0.statementHash(vk, version, input)
            ).to.be.equal(leaf);
        });
    });

    describe("verify", function () {
        it("calls the VerifyProofAggregation contract correctly", async function () {
            const { vk, version, input, leaf } = validStatementV1_0();
            const domainId = 1;
            const aggregationId = 2;
            const merklePath = [
                "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
                "0x00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"];
            const leafCount = 3;
            const index = 4;

            const expectedArgs = {
                domainId: domainId,
                aggregationId: aggregationId,
                leaf: leaf,
                merklePath: merklePath,
                leafCount: leafCount,
                index: index,
            };

            await verifyProofAggregationMock.setExpectedArgs(expectedArgs);

            await expect(
                await zkVerifyRisc0.verify(
                    vk,
                    version,
                    input,
                    domainId,
                    aggregationId,
                    merklePath,
                    leafCount,
                    index
                )
            ).to.be.equal(true);
        });
    });
});
