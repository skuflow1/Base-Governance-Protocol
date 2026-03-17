// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GovernanceProtocol {
    struct Proposal {
        address proposer;
        address target;
        uint256 value;
        bytes data;
        uint256 voteYes;
        uint256 voteNo;
        uint256 endTime;
        bool queued;
        uint256 eta;
        bool executed;
        bool cancelled;
    }

    uint256 public proposalCount;
    uint256 public quorum = 1;
    uint256 public timelockDelay = 1 days;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    event Proposed(
        uint256 indexed id,
        address indexed proposer,
        address indexed target,
        uint256 value,
        uint256 endTime
    );
    event Voted(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event Queued(uint256 indexed id, uint256 eta);
    event Executed(uint256 indexed id);
    event Cancelled(uint256 indexed id);
    event QuorumUpdated(uint256 newQuorum);
    event TimelockDelayUpdated(uint256 newDelay);

    function setQuorum(uint256 newQuorum) external {
        require(newQuorum > 0, "zero");
        quorum = newQuorum;
        emit QuorumUpdated(newQuorum);
    }

    function setTimelockDelay(uint256 newDelay) external {
        timelockDelay = newDelay;
        emit TimelockDelayUpdated(newDelay);
    }

    function propose(
        address target,
        uint256 value,
        bytes calldata data,
        uint256 duration
    ) external returns (uint256 id) {
        require(target != address(0), "target=0");
        require(duration > 0, "duration=0");

        id = ++proposalCount;

        proposals[id] = Proposal({
            proposer: msg.sender,
            target: target,
            value: value,
            data: data,
            voteYes: 0,
            voteNo: 0,
            endTime: block.timestamp + duration,
            queued: false,
            eta: 0,
            executed: false,
            cancelled: false
        });

        emit Proposed(id, msg.sender, target, value, block.timestamp + duration);
    }

    function vote(uint256 id, bool support, uint256 weight) external {
        Proposal storage p = proposals[id];
        require(p.proposer != address(0), "no proposal");
        require(!p.cancelled, "cancelled");
        require(block.timestamp < p.endTime, "ended");
        require(!voted[id][msg.sender], "already voted");
        require(weight > 0, "weight=0");

        voted[id][msg.sender] = true;

        if (support) {
            p.voteYes += weight;
        } else {
            p.voteNo += weight;
        }

        emit Voted(id, msg.sender, support, weight);
    }

    function cancel(uint256 id) external {
        Proposal storage p = proposals[id];
        require(p.proposer != address(0), "no proposal");
        require(msg.sender == p.proposer, "not proposer");
        require(!p.queued, "already queued");
        require(!p.executed, "already executed");
        require(!p.cancelled, "already cancelled");

        p.cancelled = true;
        emit Cancelled(id);
    }

    function queue(uint256 id) external {
        Proposal storage p = proposals[id];
        require(p.proposer != address(0), "no proposal");
        require(!p.cancelled, "cancelled");
        require(!p.queued, "queued");
        require(block.timestamp >= p.endTime, "not ended");
        require(p.voteYes + p.voteNo >= quorum, "quorum not met");
        require(p.voteYes > p.voteNo, "not passed");

        p.queued = true;
        p.eta = block.timestamp + timelockDelay;

        emit Queued(id, p.eta);
    }

    function execute(uint256 id) external {
        Proposal storage p = proposals[id];
        require(p.proposer != address(0), "no proposal");
        require(!p.cancelled, "cancelled");
        require(p.queued, "not queued");
        require(!p.executed, "executed");
        require(block.timestamp >= p.eta, "timelocked");

        p.executed = true;

        (bool ok, ) = p.target.call{value: p.value}(p.data);
        require(ok, "call failed");

        emit Executed(id);
    }

    receive() external payable {}
}
