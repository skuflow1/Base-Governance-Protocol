// base-governance/scripts/insights.js
const { ethers } = require("hardhat");
const fs = require("fs");

async function generateGovernanceInsights() {
  console.log("Generating insights for Base Governance Protocol...");
  
  const governanceAddress = "0x...";
  const governance = await ethers.getContractAt("GovernanceProtocolV2", governanceAddress);
  
  // Получение инсайтов
  const insights = {
    timestamp: new Date().toISOString(),
    governanceAddress: governanceAddress,
    participationMetrics: {},
    proposalEffectiveness: {},
    votingPatterns: {},
    communityHealth: {},
    improvementAreas: []
  };
  
  // Метрики участия
  const participationMetrics = await governance.getParticipationMetrics();
  insights.participationMetrics = {
    totalVoters: participationMetrics.totalVoters.toString(),
    activeVoters: participationMetrics.activeVoters.toString(),
    participationRate: participationMetrics.participationRate.toString(),
    avgVotesPerUser: participationMetrics.avgVotesPerUser.toString()
  };
  
  // Эффективность предложений
  const proposalEffectiveness = await governance.getProposalEffectiveness();
  insights.proposalEffectiveness = {
    totalProposals: proposalEffectiveness.totalProposals.toString(),
    passedProposals: proposalEffectiveness.passedProposals.toString(),
    rejectedProposals: proposalEffectiveness.rejectedProposals.toString(),
    successRate: proposalEffectiveness.successRate.toString()
  };
  
  // Паттерны голосования
  const votingPatterns = await governance.getVotingPatterns();
  insights.votingPatterns = {
    majorityConsensus: votingPatterns.majorityConsensus.toString(),
    minorityVotes: votingPatterns.minorityVotes.toString(),
    abstentions: votingPatterns.abstentions.toString()
  };
  
  // Здоровье сообщества
  const communityHealth = await governance.getCommunityHealth();
  insights.communityHealth = {
    engagementScore: communityHealth.engagementScore.toString(),
    trustIndex: communityHealth.trustIndex.toString(),
    diversityScore: communityHealth.diversityScore.toString(),
    activityLevel: communityHealth.activityLevel.toString()
  };
  
  // Области улучшения
  if (parseFloat(insights.participationMetrics.participationRate) < 30) {
    insights.improvementAreas.push("Low voter participation - implement engagement initiatives");
  }
  
  if (parseFloat(insights.proposalEffectiveness.successRate) < 50) {
    insights.improvementAreas.push("Low proposal success rate - review decision-making processes");
  }
  
  // Сохранение инсайтов
  const fileName = `governance-insights-${Date.now()}.json`;
  fs.writeFileSync(`./insights/${fileName}`, JSON.stringify(insights, null, 2));
  
  console.log("Governance insights generated successfully!");
  console.log("File saved:", fileName);
}

generateGovernanceInsights()
  .catch(error => {
    console.error("Insights error:", error);
    process.exit(1);
  });
