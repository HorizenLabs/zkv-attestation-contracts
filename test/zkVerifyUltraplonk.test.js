const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ZkVerifyUltraplonk contract", function () {
    let zkVerifyUltraplonk;
    let verifyProofAggregationMock;

    function validStatement() {
        return {
            vkHash: "0x7488c9f50af6d975b9707036995772e1f8d0b68dcd46174413321e674bdf331f",
            input: ["1", "2"],
            leaf: "0x4e2b5c9cbc025e50d5f117a70d479db60d7144ef728b43f307bc3606fdcdba4d",
        }
    };

    beforeEach(async function () {
        VerifyProofAggregationMock = await ethers.getContractFactory("VerifyProofAggregationMock");
        ZkVerifyUltraplonk = await ethers.getContractFactory("ZkVerifyUltraplonk");

        verifyProofAggregationMock = await VerifyProofAggregationMock.deploy();
        await verifyProofAggregationMock.waitForDeployment();
        zkVerifyUltraplonk = await ZkVerifyUltraplonk.deploy(verifyProofAggregationMock.getAddress());
        await zkVerifyUltraplonk.waitForDeployment();
    });

    describe("encodePublicInput", function () {
        it("works with empty input", async function () {
            const inputs = [];
            const expectedOutput = "0x";
            await expect(
                await zkVerifyUltraplonk.encodePublicInputs(inputs)
            ).to.be.equal(expectedOutput);
        });

        it("works with non-trivial input", async function () {
            const inputs = [
                "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
                "0x00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"
            ];
            const expectedOutput = "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";
            await expect(
                await zkVerifyUltraplonk.encodePublicInputs(inputs)
            ).to.be.equal(expectedOutput);
        });
    });

    describe("statementHash", function () {
        it("returns expected result", async function () {
            const { vkHash, input, leaf } = validStatement();
            await expect(
                await zkVerifyUltraplonk.statementHash(vkHash, input)
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
                await zkVerifyUltraplonk.verify(
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
