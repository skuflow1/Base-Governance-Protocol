
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovernanceProtocolV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

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

    IERC20 public token;
    uint256 public quorumThreshold; // 10% quorum
    uint256 public votingDelay; // 1 day delay
    uint256 public votingPeriod; // 7 days period
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Voter) public voters;
    mapping(uint256 => mapping(address => Vote)) public proposalVotes;
    
    uint256 public nextProposalId;
    
    // Events
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
    }

    // Create proposal
    function propose(
        string memory description
    ) external {
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
        
        emit ProposalCreated(proposalId, msg.sender, description, startTime, endTime);
    }

    // Vote on proposal
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

    // Execute proposal
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(block.timestamp > proposal.endTime, "Voting not finished");
        require(proposal.forVotes > proposal.againstVotes, "Not enough votes for");
        
        // Check quorum
        uint256 totalVoted = proposal.forVotes + proposal.againstVotes;
        uint256 totalSupply = token.totalSupply();
        require(totalVoted >= (totalSupply * quorumThreshold) / 10000, "Quorum not reached");
        
        proposal.executed = true;
        proposal.quorumReached = true;
        
        emit ProposalExecuted(proposalId);
    }

    // Cancel proposal
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer || msg.sender == owner(), "Not authorized");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal already canceled");
        
        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    // Get proposal state
    function getProposalState(uint256 proposalId) external view returns (string memory) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) return "Canceled";
        if (proposal.executed) return "Executed";
        if (block.timestamp < proposal.startTime) return "Pending";
        if (block.timestamp < proposal.endTime) return "Active";
        return "Finished";
    }

    // Get proposal info
    function getProposalInfo(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }

    // Get voting power
    function getVotingPower(address user) external view returns (uint256) {
        return token.balanceOf(user);
    }

    // Check if user can vote
    function canVote(uint256 proposalId, address user) external view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled || proposal.executed) return false;
        if (block.timestamp < proposal.startTime) return false;
        if (block.timestamp > proposal.endTime) return false;
        if (token.balanceOf(user) == 0) return false;
        return true;
    }

    // Get total votes
    function getTotalVotes() external view returns (uint256) {
        return token.totalSupply();
    }

    // Get quorum threshold
    function getQuorumThreshold() external view returns (uint256) {
        return quorumThreshold;
    }

    // Get voting period
    function getVotingPeriod() external view returns (uint256) {
        return votingPeriod;
    }

    // Get voting delay
    function getVotingDelay() external view returns (uint256) {
        return votingDelay;
    }
    // Добавить функции:
function voteQuadratic(
    uint256 proposalId,
    bool support,
    uint256 votes
) external {
    // Квадратичное голосование
    // Количество голосов возводится в квадрат
}

function calculateQuadraticVotes(address user, uint256 amount) external view returns (uint256) {
    // Расчет квадратичных голосов
    return amount * amount;
}
// Добавить структуры:
struct Delegation {
    address delegator;
    address delegatee;
    uint256 amount;
    uint256 expirationTime;
    uint256 delegationId;
    bool active;
    string purpose;
}

struct DelegationLimit {
    address delegatee;
    uint256 maxDelegatedAmount;
    uint256 maxProposals;
    uint256 delegationWindow;
    bool enabled;
    uint256 lastDelegationTime;
}

struct DelegationHistory {
    address delegator;
    address delegatee;
    uint256 amount;
    uint256 timestamp;
    string action;
}

// Добавить маппинги:
mapping(address => Delegation) public delegations;
mapping(address => DelegationLimit) public delegationLimits;
mapping(address => DelegationHistory[]) public delegationHistory;

// Добавить события:
event DelegationCreated(
    address indexed delegator,
    address indexed delegatee,
    uint256 amount,
    uint256 expirationTime,
    string purpose
);

event DelegationUpdated(
    address indexed delegator,
    address indexed delegatee,
    uint256 amount,
    uint256 timestamp
);

event DelegationRevoked(
    address indexed delegator,
    address indexed delegatee,
    uint256 timestamp
);

event DelegationLimitSet(
    address indexed delegatee,
    uint256 maxAmount,
    uint256 maxProposals,
    uint256 window,
    bool enabled
);

// Добавить функции:
function setDelegationLimit(
    address delegatee,
    uint256 maxDelegatedAmount,
    uint256 maxProposals,
    uint256 delegationWindow
) external onlyOwner {
    require(delegatee != address(0), "Invalid delegatee");
    
    delegationLimits[delegatee] = DelegationLimit({
        delegatee: delegatee,
        maxDelegatedAmount: maxDelegatedAmount,
        maxProposals: maxProposals,
        delegationWindow: delegationWindow,
        enabled: true,
        lastDelegationTime: block.timestamp
    });
    
    emit DelegationLimitSet(delegatee, maxDelegatedAmount, maxProposals, delegationWindow, true);
}

function createDelegation(
    address delegatee,
    uint256 amount,
    uint256 duration,
    string memory purpose
) external {
    require(delegatee != address(0), "Invalid delegatee");
    require(amount > 0, "Amount must be greater than 0");
    require(balanceOf(msg.sender) >= amount, "Insufficient balance");
    
    // Check delegation limits
    DelegationLimit storage limit = delegationLimits[delegatee];
    require(limit.enabled, "Delegation not allowed");
    require(block.timestamp >= limit.lastDelegationTime + limit.delegationWindow, "Delegation window not open");
    
    // Check maximum delegated amount
    if (limit.maxDelegatedAmount > 0) {
        uint256 totalDelegated = getTotalDelegated(delegatee);
        require(totalDelegated + amount <= limit.maxDelegatedAmount, "Maximum delegation amount exceeded");
    }
    
    // Create delegation
    uint256 delegationId = uint256(keccak256(abi.encodePacked(msg.sender, delegatee, block.timestamp)));
    
    delegations[msg.sender] = Delegation({
        delegator: msg.sender,
        delegatee: delegatee,
        amount: amount,
        expirationTime: block.timestamp + duration,
        delegationId: delegationId,
        active: true,
        purpose: purpose
    });
    
    // Add to history
    delegationHistory[msg.sender].push(DelegationHistory({
        delegator: msg.sender,
        delegatee: delegatee,
        amount: amount,
        timestamp: block.timestamp,
        action: "created"
    }));
    
    limit.lastDelegationTime = block.timestamp;
    
    emit DelegationCreated(msg.sender, delegatee, amount, block.timestamp + duration, purpose);
}

function updateDelegation(
    address delegatee,
    uint256 newAmount,
    uint256 duration
) external {
    require(delegations[msg.sender].delegator == msg.sender, "No existing delegation");
    require(delegatee == delegations[msg.sender].delegatee, "Invalid delegatee");
    require(newAmount > 0, "Amount must be greater than 0");
    require(balanceOf(msg.sender) >= newAmount, "Insufficient balance");
    
    // Update delegation
    delegations[msg.sender].amount = newAmount;
    delegations[msg.sender].expirationTime = block.timestamp + duration;
    delegations[msg.sender].active = true;
    
    // Add to history
    delegationHistory[msg.sender].push(DelegationHistory({
        delegator: msg.sender,
        delegatee: delegatee,
        amount: newAmount,
        timestamp: block.timestamp,
        action: "updated"
    }));
    
    emit DelegationUpdated(msg.sender, delegatee, newAmount, block.timestamp);
}

function revokeDelegation(address delegatee) external {
    require(delegations[msg.sender].delegator == msg.sender, "No existing delegation");
    require(delegatee == delegations[msg.sender].delegatee, "Invalid delegatee");
    
    // Revoke delegation
    delegations[msg.sender].active = false;
    
    // Add to history
    delegationHistory[msg.sender].push(DelegationHistory({
        delegator: msg.sender,
        delegatee: delegatee,
        amount: delegations[msg.sender].amount,
        timestamp: block.timestamp,
        action: "revoked"
    }));
    
    emit DelegationRevoked(msg.sender, delegatee, block.timestamp);
}

function getTotalDelegated(address delegatee) internal view returns (uint256) {
    uint256 total = 0;
    // Implementation would iterate through all delegations
    return total;
}

function getDelegationInfo(address delegator) external view returns (Delegation memory) {
    return delegations[delegator];
}

function getDelegationLimits(address delegatee) external view returns (DelegationLimit memory) {
    return delegationLimits[delegatee];
}

function getDelegationHistory(address user) external view returns (DelegationHistory[] memory) {
    return delegationHistory[user];
}

function getActiveDelegations() external view returns (address[] memory) {
    // Implementation would return active delegations
    return new address[](0);
}
}
