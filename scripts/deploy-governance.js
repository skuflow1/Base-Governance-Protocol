
const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Base Governance Protocol...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Деплой токена
  const GovernanceToken = await ethers.getContractFactory("ERC20Token");
  const governanceToken = await GovernanceToken.deploy("Governance Token", "GOV");
  await governanceToken.deployed();

  // Деплой Governance Protocol контракта
  const GovernanceProtocol = await ethers.getContractFactory("GovernanceProtocolV2");
  const governance = await GovernanceProtocol.deploy(
    governanceToken.address,
    1000, // 10% quorum threshold
    86400, // 1 day voting delay
    604800, // 7 days voting period
    ethers.utils.parseEther("1000") // 1000 tokens minimum proposal threshold
  );

  await governance.deployed();

  console.log("Base Governance Protocol deployed to:", governance.address);
  console.log("Governance Token deployed to:", governanceToken.address);
  
  // Сохраняем адреса
  const fs = require("fs");
  const data = {
    governance: governance.address,
    governanceToken: governanceToken.address,
    owner: deployer.address
  };
  
  fs.writeFileSync("./config/deployment.json", JSON.stringify(data, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
