const fs = require("fs");
const path = require("path");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // Optional: deploy ProposalManager first if needed
  let pmAddr = "";
  try {
    const PM = await ethers.getContractFactory("ProposalManager");
    const pm = await PM.deploy();
    await pm.deployed();
    pmAddr = pm.address;
    console.log("ProposalManager:", pmAddr);
  } catch (e) {
    console.log("ProposalManager not deployed (constructor mismatch or missing). Skipped.");
  }

  const Gov = await ethers.getContractFactory("GovernanceProtocol");
  const gov = await Gov.deploy();
  await gov.deployed();

  console.log("GovernanceProtocol:", gov.address);

  const out = {
    network: hre.network.name,
    chainId: (await ethers.provider.getNetwork()).chainId,
    deployer: deployer.address,
    contracts: {
      ProposalManager: pmAddr || null,
      GovernanceProtocol: gov.address
    }
  };

  const outPath = path.join(__dirname, "..", "deployments.json");
  fs.writeFileSync(outPath, JSON.stringify(out, null, 2));
  console.log("Saved:", outPath);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
