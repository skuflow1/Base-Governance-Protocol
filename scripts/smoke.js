require("dotenv").config();
const fs = require("fs");
const path = require("path");

async function main() {
  const depPath = path.join(__dirname, "..", "deployments.json");
  const deployments = JSON.parse(fs.readFileSync(depPath, "utf8"));

  const farmAddr = deployments.contracts.YieldFarm;
  const stakeAddr = deployments.contracts.StakeToken;
  const rewardAddr = deployments.contracts.RewardToken;

  const [owner, user] = await ethers.getSigners();
  const farm = await ethers.getContractAt("YieldFarm", farmAddr);
  const stake = await ethers.getContractAt("RewardToken", stakeAddr);
  const reward = await ethers.getContractAt("RewardToken", rewardAddr);

  console.log("YieldFarm:", farmAddr);

  // Mint some stake + rewards to owner, then fund farm
  const amt = ethers.utils.parseUnits("100", 18);
  await (await stake.mint(user.address, amt)).wait();
  await (await reward.mint(owner.address, amt)).wait();
  await (await reward.approve(farmAddr, amt)).wait();
  await (await farm.fundRewards(amt)).wait();
  console.log("Funded rewards");

  // Stake
  await (await stake.connect(user).approve(farmAddr, amt)).wait();
  await (await farm.connect(user).deposit(amt)).wait();
  console.log("Deposited");

  // Mine a few blocks (hardhat local only)
  if (hre.network.name === "hardhat") {
    for (let i = 0; i < 5; i++) await ethers.provider.send("evm_mine", []);
  }

  // Claim
  await (await farm.connect(user).claim()).wait();
  console.log("Claimed");

  // Emergency withdraw
  await (await farm.connect(user).emergencyWithdraw()).wait();
  console.log("EmergencyWithdraw OK");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

