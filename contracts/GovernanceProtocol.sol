# base-governance/contracts/GovernanceProtocol.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceProtocol is Ownable {
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        bool quorumReached;
    }
    
    struct Vote {
        bool support;
        uint256 votes;
    }
    
    struct Voter {
        uint256 votingPower;
        mapping(uint256 => bool) hasVoted;
    }
    
    struct ProposalDetail {
        address target;
        bytes data;
        uint256 value;
        string description;
    }
    
    IERC20 public token;
    uint256 public quorumThreshold; // Percentage of total supply needed for quorum
    uint256 public votingDelay; // Delay before voting starts
    uint256 public votingPeriod; // Duration of voting period
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Voter) public voters;
    mapping(uint256 => mapping(address => Vote)) public proposalVotes;
    mapping(uint256 => ProposalDetail) public proposalDetails;
    
    uint256 public nextProposalId;
    uint256 public totalSupply;
    
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        uint256 startTime,
        uint256 endTime
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 votes
    );
    
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    
    constructor(
        address _token,
        uint256 _quorumThreshold,
        uint256 _votingDelay,
        uint256 _votingPeriod
    ) {
        token = IERC20(_token);
        quorumThreshold = _quorumThreshold;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        totalSupply = token.totalSupply();
    }
    
    function propose(
        ProposalDetail[] memory proposalDetails,
        string memory description
    ) external {
        require(proposalDetails.length > 0, "Empty proposal");
        require(token.balanceOf(msg.sender) > 0, "Insufficient balance");
        
        uint256 proposalId = nextProposalId++;
        uint256 startTime = block.timestamp + votingDelay;
        uint256 endTime = startTime + votingPeriod;
        
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: description,
            startTime: startTime,
            endTime: endTime,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            canceled: false,
            quorumReached: false
        });
        
        // Store proposal details
        for (uint256 i = 0; i < proposalDetails.length; i++) {
            proposalDetails[proposalId] = proposalDetails[i];
        }
        
        emit ProposalCreated(proposalId, msg.sender, description, startTime, endTime);
    }
    
    function vote(
        uint256 proposalId,
        bool support
    ) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.canceled, "Proposal canceled");
        require(!proposal.executed, "Proposal executed");
        require(!proposalVotes[proposalId][msg.sender].support, "Already voted");
        
        uint256 votingPower = token.balanceOf(msg.sender);
        require(votingPower > 0, "No voting power");
        
        proposalVotes[proposalId][msg.sender] = Vote({
            support: support,
            votes: votingPower
        });
        
        if (support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }
        
        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }
    
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(block.timestamp > proposal.endTime, "Voting not finished");
        require(proposal.forVotes > proposal.againstVotes, "Not enough votes for");
        
        // Check quorum requirement
        uint256 totalVoted = proposal.forVotes + proposal.againstVotes;
        require(totalVoted >= (totalSupply * quorumThreshold) / 100, "Quorum not reached");
        
        proposal.executed = true;
        
        // Execute proposal details
        for (uint256 i = 0; i < proposalDetails[proposalId].length; i++) {
            ProposalDetail memory detail = proposalDetails[proposalId][i];
            (bool success,) = detail.target.call{value: detail.value}(detail.data);
            require(success, "Execution failed");
        }
        
        emit ProposalExecuted(proposalId);
    }
    
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer || msg.sender == owner(), "Not authorized");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal already canceled");
        
        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }
    
    function getProposalState(uint256 proposalId) external view returns (string memory) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) return "Canceled";
        if (proposal.executed) return "Executed";
        if (block.timestamp < proposal.startTime) return "Pending";
        if (block.timestamp < proposal.endTime) return "Active";
        return "Finished";
    }
}
