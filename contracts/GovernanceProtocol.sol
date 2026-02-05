
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

mapping(address => Delegation) public delegations;
mapping(address => DelegationLimit) public delegationLimits;
mapping(address => DelegationHistory[]) public delegationHistory;


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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovernanceProtocol is Ownable, ReentrancyGuard {
    using SafeMath for uint256;


    
    // Новые структуры для делегирования с ограничениями
    struct Delegation {
        address delegator;
        address delegatee;
        uint256 amount;
        uint256 expirationTime;
        uint256 delegationId;
        bool active;
        string purpose;
        uint256 maxDelegationAmount;
        uint256 maxProposals;
        uint256 delegationWindow;
        uint256 lastDelegationTime;
        uint256 totalDelegated;
        uint256 proposalCount;
        uint256[] delegatedProposals;
        mapping(address => bool) votedProposals;
    }
    
    struct DelegationLimit {
        address delegatee;
        uint256 maxDelegatedAmount;
        uint256 maxProposals;
        uint256 delegationWindow;
        uint256 minVotingPower;
        uint256 maxVotingPower;
        bool enabled;
        uint256 lastUpdated;
        uint256[] restrictedProposals;
        uint256[] allowedProposals;
    }
    
    struct DelegationHistory {
        address delegator;
        address delegatee;
        uint256 amount;
        uint256 timestamp;
        string action;
        string reason;
    }
    
    struct VotingPower {
        address user;
        uint256 votingPower;
        uint256 delegatedPower;
        uint256 directPower;
        uint256 lastUpdate;
        uint256[] delegatedTo;
        uint256[] delegatedFrom;
        mapping(address => bool) isDelegatedTo;
    }
    
    struct ProposalDelegation {
        uint256 proposalId;
        address delegatee;
        uint256 votingPower;
        uint256 delegationTimestamp;
        bool executed;
        uint256[] delegatedProposals;
    }
    
    // Новые маппинги
    mapping(address => Delegation) public delegations;
    mapping(address => DelegationLimit) public delegationLimits;
    mapping(address => VotingPower) public votingPowers;
    mapping(address => mapping(uint256 => ProposalDelegation)) public proposalDelegations;
    mapping(address => DelegationHistory[]) public delegationHistory;
    mapping(address => mapping(address => bool)) public delegationRestrictions;
    mapping(address => mapping(uint256 => bool)) public proposalDelegationRestrictions;
    
    // Новые события
    event DelegationCreated(
        address indexed delegator,
        address indexed delegatee,
        uint256 amount,
        uint256 expirationTime,
        string purpose,
        uint256 maxDelegationAmount,
        uint256 maxProposals
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
        uint256 timestamp,
        string reason
    );
    
    event DelegationLimitSet(
        address indexed delegatee,
        uint256 maxAmount,
        uint256 maxProposals,
        uint256 window,
        uint256 minVotingPower,
        uint256 maxVotingPower,
        bool enabled
    );
    
    event DelegationRestrictionSet(
        address indexed delegator,
        address indexed delegatee,
        bool restricted,
        string reason
    );
    
    event ProposalDelegationCreated(
        uint256 indexed proposalId,
        address indexed delegatee,
        uint256 votingPower,
        uint256 timestamp
    );
    
    event VotingPowerUpdated(
        address indexed user,
        uint256 votingPower,
        uint256 timestamp,
        string updateType
    );
    
    // Новые функции для делегирования с ограничениями
    function setDelegationLimit(
        address delegatee,
        uint256 maxDelegatedAmount,
        uint256 maxProposals,
        uint256 delegationWindow,
        uint256 minVotingPower,
        uint256 maxVotingPower,
        bool enabled,
        uint256[] memory restrictedProposals,
        uint256[] memory allowedProposals
    ) external onlyOwner {
        require(delegatee != address(0), "Invalid delegatee");
        require(maxDelegatedAmount >= 0, "Max delegation amount must be non-negative");
        require(maxProposals >= 0, "Max proposals must be non-negative");
        require(delegationWindow >= 3600, "Delegation window too short (minimum 1 hour)");
        require(minVotingPower <= maxVotingPower, "Invalid voting power range");
        
        delegationLimits[delegatee] = DelegationLimit({
            delegatee: delegatee,
            maxDelegatedAmount: maxDelegatedAmount,
            maxProposals: maxProposals,
            delegationWindow: delegationWindow,
            minVotingPower: minVotingPower,
            maxVotingPower: maxVotingPower,
            enabled: enabled,
            lastUpdated: block.timestamp,
            restrictedProposals: restrictedProposals,
            allowedProposals: allowedProposals
        });
        
        emit DelegationLimitSet(
            delegatee,
            maxDelegatedAmount,
            maxProposals,
            delegationWindow,
            minVotingPower,
            maxVotingPower,
            enabled
        );
    }
    
    function createDelegation(
        address delegatee,
        uint256 amount,
        uint256 duration,
        string memory purpose,
        uint256 maxDelegationAmount,
        uint256 maxProposals
    ) external {
        require(delegatee != address(0), "Invalid delegatee");
        require(amount > 0, "Amount must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(delegationLimits[delegatee].enabled, "Delegation not enabled for delegatee");
        
        // Проверка ограничений делегирования
        DelegationLimit storage limit = delegationLimits[delegatee];
        require(limit.maxDelegatedAmount == 0 || amount <= limit.maxDelegatedAmount, "Delegation amount exceeds limit");
        require(limit.maxProposals == 0 || limit.proposalCount < limit.maxProposals, "Maximum proposals exceeded");
        
        // Проверка временного окна
        if (limit.delegationWindow > 0) {
            require(block.timestamp >= limit.lastUpdated + limit.delegationWindow, "Delegation window not open");
        }
        
        // Проверка минимального и максимального голосующего веса
        uint256 userVotingPower = calculateVotingPower(msg.sender);
        require(userVotingPower >= limit.minVotingPower, "Insufficient voting power");
        require(userVotingPower <= limit.maxVotingPower, "Excessive voting power");
        
        // Создание делегирования
        uint256 delegationId = uint256(keccak256(abi.encodePacked(msg.sender, delegatee, block.timestamp)));
        
        delegations[msg.sender] = Delegation({
            delegator: msg.sender,
            delegatee: delegatee,
            amount: amount,
            expirationTime: block.timestamp + duration,
            delegationId: delegationId,
            active: true,
            purpose: purpose,
            maxDelegationAmount: maxDelegationAmount,
            maxProposals: maxProposals,
            delegationWindow: limit.delegationWindow,
            lastDelegationTime: block.timestamp,
            totalDelegated: amount,
            proposalCount: 0,
            delegatedProposals: new uint256[](0),
            votedProposals: new mapping(address => bool)
        });
        
        // Обновить статистику
        limit.lastUpdated = block.timestamp;
        limit.proposalCount++;
        
        // Добавить в историю
        delegationHistory[msg.sender].push(DelegationHistory({
            delegator: msg.sender,
            delegatee: delegatee,
            amount: amount,
            timestamp: block.timestamp,
            action: "created",
            reason: purpose
        }));
        
        // Обновить голосующий вес
        updateVotingPower(msg.sender, amount, "delegated");
        
        emit DelegationCreated(
            msg.sender,
            delegatee,
            amount,
            block.timestamp + duration,
            purpose,
            maxDelegationAmount,
            maxProposals
        );
    }
    
    function updateDelegation(
        address delegatee,
        uint256 newAmount,
        uint256 duration,
        string memory purpose
    ) external {
        require(delegatee != address(0), "Invalid delegatee");
        require(newAmount > 0, "Amount must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        require(delegations[msg.sender].delegator == msg.sender, "No existing delegation");
        require(delegations[msg.sender].delegatee == delegatee, "Invalid delegatee");
        require(delegations[msg.sender].active, "Delegation not active");
        require(balanceOf(msg.sender) >= newAmount, "Insufficient balance");
        
        // Проверка ограничений
        DelegationLimit storage limit = delegationLimits[delegatee];
        require(limit.maxDelegatedAmount == 0 || newAmount <= limit.maxDelegatedAmount, "Delegation amount exceeds limit");
        
        // Обновить делегирование
        delegations[msg.sender].amount = newAmount;
        delegations[msg.sender].expirationTime = block.timestamp + duration;
        delegations[msg.sender].purpose = purpose;
        delegations[msg.sender].totalDelegated = delegations[msg.sender].totalDelegated.add(newAmount - delegations[msg.sender].amount);
        
        // Обновить статистику
        limit.lastUpdated = block.timestamp;
        
        // Обновить историю
        delegationHistory[msg.sender].push(DelegationHistory({
            delegator: msg.sender,
            delegatee: delegatee,
            amount: newAmount,
            timestamp: block.timestamp,
            action: "updated",
            reason: purpose
        }));
        
        // Обновить голосующий вес
        updateVotingPower(msg.sender, newAmount, "updated");
        
        emit DelegationUpdated(msg.sender, delegatee, newAmount, block.timestamp);
    }
    
    function revokeDelegation(address delegatee) external {
        require(delegatee != address(0), "Invalid delegatee");
        require(delegations[msg.sender].delegator == msg.sender, "No existing delegation");
        require(delegations[msg.sender].delegatee == delegatee, "Invalid delegatee");
        
        // Проверка, что делегирование активно
        require(delegations[msg.sender].active, "Delegation not active");
        
        // Отменить делегирование
        delegations[msg.sender].active = false;
        
        // Обновить историю
        delegationHistory[msg.sender].push(DelegationHistory({
            delegator: msg.sender,
            delegatee: delegatee,
            amount: delegations[msg.sender].amount,
            timestamp: block.timestamp,
            action: "revoked",
            reason: "Manual revocation"
        }));
        
        // Обновить голосующий вес
        updateVotingPower(msg.sender, 0, "revoked");
        
        emit DelegationRevoked(msg.sender, delegatee, block.timestamp, "Manual revocation");
    }
    
    function setDelegationRestriction(
        address delegator,
        address delegatee,
        bool restricted,
        string memory reason
    ) external onlyOwner {
        require(delegator != address(0), "Invalid delegator");
        require(delegatee != address(0), "Invalid delegatee");
        
        delegationRestrictions[delegator][delegatee] = restricted;
        
        emit DelegationRestrictionSet(delegator, delegatee, restricted, reason);
    }
    
    function createProposalDelegation(
        uint256 proposalId,
        address delegatee,
        uint256 votingPower,
        string memory reason
    ) external {
        require(delegatee != address(0), "Invalid delegatee");
        require(votingPower > 0, "Voting power must be greater than 0");
        require(proposalId > 0, "Invalid proposal ID");
        
        // Проверка ограничений
        require(!delegationRestrictions[msg.sender][delegatee], "Delegation restricted");
        require(delegationLimits[delegatee].enabled, "Delegation not enabled for delegatee");
        
        // Проверка, что делегирование уже существует
        require(delegations[msg.sender].delegator == msg.sender, "No existing delegation");
        require(delegations[msg.sender].delegatee == delegatee, "Invalid delegatee");
        require(delegations[msg.sender].active, "Delegation not active");
        
        // Проверка ограничений токенов
        DelegationLimit storage limit = delegationLimits[delegatee];
        require(limit.maxProposals == 0 || limit.proposalCount < limit.maxProposals, "Maximum proposals exceeded");
        
        // Создать делегирование предложения
        proposalDelegations[msg.sender][proposalId] = ProposalDelegation({
            proposalId: proposalId,
            delegatee: delegatee,
            votingPower: votingPower,
            delegationTimestamp: block.timestamp,
            executed: false,
            delegatedProposals: new uint256[](0)
        });
        
        // Обновить статистику
        limit.proposalCount++;
        
        // Обновить историю
        delegationHistory[msg.sender].push(DelegationHistory({
            delegator: msg.sender,
            delegatee: delegatee,
            amount: votingPower,
            timestamp: block.timestamp,
            action: "proposal_delegated",
            reason: reason
        }));
        
        emit ProposalDelegationCreated(proposalId, delegatee, votingPower, block.timestamp);
    }
    
    function updateVotingPower(
        address user,
        uint256 amount,
        string memory updateType
    ) internal {
        VotingPower storage power = votingPowers[user];
        power.user = user;
        power.votingPower = amount;
        power.lastUpdate = block.timestamp;
        
        emit VotingPowerUpdated(user, amount, block.timestamp, updateType);
    }
    
    function calculateVotingPower(address user) internal view returns (uint256) {
        // Простая реализация - в реальной системе будет сложнее
        return balanceOf(user);
    }
    
    function getDelegationInfo(address delegator) external view returns (Delegation memory) {
        return delegations[delegator];
    }
    
    function getDelegationLimit(address delegatee) external view returns (DelegationLimit memory) {
        return delegationLimits[delegatee];
    }
    
    function getVotingPower(address user) external view returns (VotingPower memory) {
        return votingPowers[user];
    }
    
    function getDelegationHistory(address user) external view returns (DelegationHistory[] memory) {
        return delegationHistory[user];
    }
    
    function isDelegationRestricted(address delegator, address delegatee) external view returns (bool) {
        return delegationRestrictions[delegator][delegatee];
    }
    
    function getDelegationStats() external view returns (
        uint256 totalDelegations,
        uint256 activeDelegations,
        uint256 revokedDelegations,
        uint256 totalVotingPower,
        uint256 avgDelegationAmount
    ) {
        uint256 totalDelegationsCount = 0;
        uint256 activeDelegationsCount = 0;
        uint256 revokedDelegationsCount = 0;
        uint256 totalVotingPowerAmount = 0;
        uint256 totalAmount = 0;
        
        // Подсчет статистики
        for (uint256 i = 0; i < 10000; i++) {
            if (delegations[i].delegator != address(0)) {
                totalDelegationsCount++;
                totalAmount = totalAmount.add(delegations[i].amount);
                totalVotingPowerAmount = totalVotingPowerAmount.add(delegations[i].amount);
                
                if (delegations[i].active) {
                    activeDelegationsCount++;
                } else {
                    revokedDelegationsCount++;
                }
            }
        }
        
        uint256 avgAmount = totalDelegationsCount > 0 ? totalAmount / totalDelegationsCount : 0;
        
        return (
            totalDelegationsCount,
            activeDelegationsCount,
            revokedDelegationsCount,
            totalVotingPowerAmount,
            avgAmount
        );
    }
    
    function getDelegationByUser(address user) external view returns (Delegation[] memory) {
        // Возвращает все делегирования пользователя
        return new Delegation[](0);
    }
    
    function getProposalDelegation(uint256 proposalId, address delegator) external view returns (ProposalDelegation memory) {
        return proposalDelegations[delegator][proposalId];
    }
    
    function getUserDelegationStats(address user) external view returns (
        uint256 totalDelegated,
        uint256 activeDelegations,
        uint256 proposalCount,
        uint256 votingPower,
        uint256 lastUpdate
    ) {
        Delegation storage delegation = delegations[user];
        VotingPower storage power = votingPowers[user];
        
        return (
            delegation.totalDelegated,
            delegation.active ? 1 : 0,
            delegation.proposalCount,
            power.votingPower,
            power.lastUpdate
        );
    }
    
    function getDelegationRestrictions() external view returns (
        mapping(address => mapping(address => bool)) memory,
        mapping(address => mapping(uint256 => bool)) memory
    ) {
        return (delegationRestrictions, proposalDelegationRestrictions);
    }
}
}
