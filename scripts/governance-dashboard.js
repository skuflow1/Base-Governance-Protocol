// base-governance/scripts/dashboard.js
const { ethers } = require("hardhat");

async function generateGovernanceDashboard() {
  console.log("Generating Base Governance Dashboard...");
  
  const governanceAddress = "0x...";
  const governance = await ethers.getContractAt("GovernanceProtocolV2", governanceAddress);
  
  // Получение статистики
  const govStats = await governance.getGovernanceStats();
  console.log("Governance Stats:", {
    totalProposals: govStats.totalProposals.toString(),
    activeProposals: govStats.activeProposals.toString(),
    completedProposals: govStats.completedProposals.toString(),
    passedProposals: govStats.passedProposals.toString(),
    rejectedProposals: govStats.rejectedProposals.toString(),
    totalVotesCast: govStats.totalVotesCast.toString(),
    totalVoters: govStats.totalVoters.toString()
  });
  
  // Получение информации о последних предложениях
  const recentProposals = await governance.getRecentProposals(5);
  console.log("Recent Proposals:", recentProposals);
  
  // Получение информации о пользователях
  const userStats = await governance.getUserStats();
  console.log("User Stats:", {
    totalUsers: userStats.totalUsers.toString(),
    activeUsers: userStats.activeUsers.toString(),
    avgVotingPower: userStats.avgVotingPower.toString()
  });
  
  // Получение информации о делегатах
  const delegateStats = await governance.getDelegateStats();
  console.log("Delegate Stats:", {
    totalDelegates: delegateStats.totalDelegates.toString(),
    totalDelegators: delegateStats.totalDelegators.toString(),
    avgDelegation: delegateStats.avgDelegation.toString()
  });
  
  // Генерация дашборда
  const fs = require("fs");
  const dashboard = {
    timestamp: new Date().toISOString(),
    governanceAddress: governanceAddress,
    dashboard: {
      govStats: govStats,
      recentProposals: recentProposals,
      userStats: userStats,
      delegateStats: delegateStats
    }
  };
  
  fs.writeFileSync("./reports/governance-dashboard.json", JSON.stringify(dashboard, null, 2));
  
  console.log("Governance dashboard generated successfully!");
}

generateGovernanceDashboard()
  .catch(error => {
    console.error("Dashboard error:", error);
    process.exit(1);
  });
