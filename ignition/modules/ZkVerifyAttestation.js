const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("ZkVerifyAttestationModule", (m) => {
  const operator = m.getParameter("operator");

  const zkVerifyAttestation = m.contract("ZkVerifyAttestation", [operator]);

  return { zkVerifyAttestation };
});
