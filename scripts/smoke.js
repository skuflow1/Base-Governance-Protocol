require("dotenv").config();
const fs = require("fs");


async function main() {
  const depPath = path.join(__dirname, "..", "deployments.json");
  const deployments = JSON.parse(fs.readFileSync(depPath, "utf8"));

  const govAddr = deployments.contracts.GovernanceProtocol;
  const gov = await ethers.getContractAt("GovernanceProtocol", govAddr);

  console.log("Gov:", govAddr);

  // propose sending 0 ETH to self (no-op call)
  const [user] = await ethers.getSigners();
  const data = "0x";
  const tx = await gov.propose(user.address, 0, data, 10);
  const r = await tx.wait();
  const id = r.events.find((e) => e.event === "Proposed").args.id.toString();
  console.log("Proposal id:", id);

  await (await gov.vote(id, true, 1)).wait();
  console.log("Voted yes");

  if (hre.network.name === "hardhat") {
    await ethers.provider.send("evm_increaseTime", [11]);
    await ethers.provider.send("evm_mine", []);
  }

  await (await gov.queue(id)).wait();
  console.log("Queued");

  if (hre.network.name === "hardhat") {
    const delay = await gov.timelockDelay();
    await ethers.provider.send("evm_increaseTime", [Number(delay) + 1]);
    await ethers.provider.send("evm_mine", []);
  }

  await (await gov.execute(id)).wait();
  console.log("Executed");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
