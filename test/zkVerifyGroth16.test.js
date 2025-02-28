const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ZkVerifyGroth16 contract", function () {
    let zkVerifyGroth16;
    let verifyProofAggregationMock;

    function validStatement() {
        return {
            vkHash: "0x03cd0bc2734df75ba69a2328fa4bac1bc4981c6942a421826d36e6cb00318df7",
            input: ["42", "24"],
            leaf: "0xabb62e0715075b88517eaae0aee8671d38804ba75d1c133feec6836c443ab3a4",
        }
    };

    beforeEach(async function () {
        VerifyProofAggregationMock = await ethers.getContractFactory("VerifyProofAggregationMock");
        ZkVerifyGroth16 = await ethers.getContractFactory("ZkVerifyGroth16");

        verifyProofAggregationMock = await VerifyProofAggregationMock.deploy();
        await verifyProofAggregationMock.waitForDeployment();
        zkVerifyGroth16 = await ZkVerifyGroth16.deploy(verifyProofAggregationMock.getAddress());
        await zkVerifyGroth16.waitForDeployment();
    });

    describe("encodePublicInput", function () {
        it("works with empty input", async function () {
            const inputs = [];
            const expectedOutput = "0x";
            await expect(
                await zkVerifyGroth16.encodePublicInputs(inputs)
            ).to.be.equal(expectedOutput);
        });

        it("works with non-trivial input", async function () {
            const inputs = [
                "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
                "0x00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"
            ];
            const expectedOutput = "0x1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100";
            await expect(
                await zkVerifyGroth16.encodePublicInputs(inputs)
            ).to.be.equal(expectedOutput);
        });
    });

    describe("statementHash", function () {
        it("returns expected result", async function () {
            const { vkHash, input, leaf } = validStatement();
            await expect(
                await zkVerifyGroth16.statementHash(vkHash, input)
            ).to.be.equal(leaf);
        });
    });

    describe("verify", function () {
        it("calls the VerifyProofAggregation contract correctly", async function () {
            const { vkHash, input, leaf } = validStatement();
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
                await zkVerifyGroth16.verify(
                    vkHash,
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
