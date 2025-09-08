// base-governance/scripts/compliance-check.js
const { ethers } = require("hardhat");
const fs = require("fs");

async function checkGovernanceCompliance() {
  console.log("Checking compliance for Base Governance Protocol...");
  
  const governanceAddress = "0x...";
  const governance = await ethers.getContractAt("GovernanceProtocolV2", governanceAddress);
  
  // Получение информации о соответствии
  const complianceData = {};
  
  // Проверка прав собственности
  const owner = await governance.owner();
  complianceData.owner = owner;
  console.log("Governance owner:", owner);
  
  // Проверка кворума
  const quorum = await governance.getQuorum();
  complianceData.quorum = quorum.toString();
  console.log("Quorum requirement:", quorum.toString());
  
  // Проверка времени голосования
  const votingPeriod = await governance.getVotingPeriod();
  complianceData.votingPeriod = votingPeriod.toString();
  console.log("Voting period:", votingPeriod.toString());
  
  // Проверка предложения
  const proposalThreshold = await governance.getProposalThreshold();
  complianceData.proposalThreshold = proposalThreshold.toString();
  console.log("Proposal threshold:", proposalThreshold.toString());
  
  // Проверка активных предложений
  const activeProposals = await governance.getActiveProposals();
  complianceData.activeProposals = activeProposals.length;
  console.log("Active proposals:", activeProposals.length);
  
  // Проверка голосования
  const totalVotes = await governance.getTotalVotes();
  complianceData.totalVotes = totalVotes.toString();
  console.log("Total votes cast:", totalVotes.toString());
  
  // Проверка соответствия требованиям
  const complianceReport = {
    timestamp: new Date().toISOString(),
    governanceAddress: governanceAddress,
    complianceData: complianceData,
    complianceStatus: "COMPLIANT",
    violations: [],
    recommendations: []
  };
  
  // Проверка на нарушения
  if (parseInt(quorum.toString()) < 1000) {
    complianceReport.violations.push("Quorum too low");
    complianceReport.complianceStatus = "NON_COMPLIANT";
  }
  
  if (parseInt(votingPeriod.toString()) < 86400) {
    complianceReport.violations.push("Voting period too short");
    complianceReport.complianceStatus = "NON_COMPLIANT";
  }
  
  if (activeProposals.length > 100) {
    complianceReport.recommendations.push("Consider implementing proposal limits");
  }
  
  // Сохранение отчета
  fs.writeFileSync(`./compliance/compliance-check-${Date.now()}.json`, JSON.stringify(complianceReport, null, 2));
  
  console.log("Compliance check completed successfully!");
  console.log("Status:", complianceReport.complianceStatus);
}

checkGovernanceCompliance()
  .catch(error => {
    console.error("Compliance check error:", error);
    process.exit(1);
  });
