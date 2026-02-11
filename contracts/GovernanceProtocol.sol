


contract GovernanceProtocol {
    uint256 public timelockDelay = 1 days; 

    struct Proposal {
        address target;
        uint256 value;
        bytes data;
        uint256 voteYes;
        uint256 voteNo;
        uint256 endTime;
        bool queued;
        uint256 eta;
        bool executed;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    event Proposed(uint256 indexed id, address indexed target, uint256 value, uint256 endTime);
    event Voted(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event Queued(uint256 indexed id, uint256 eta);
    event Executed(uint256 indexed id);

    function setTimelockDelay(uint256 d) external {
        timelockDelay = d;
    }

    function propose(address target, uint256 value, bytes calldata data, uint256 duration) external returns (uint256 id) {
        require(target != address(0), "target=0");
        id = ++proposalCount;
        proposals[id] = Proposal({
            target: target,
            value: value,
            data: data,
            voteYes: 0,
            voteNo: 0,
            endTime: block.timestamp + duration,
            queued: false,
            eta: 0,
            executed: false
        });
        emit Proposed(id, target, value, proposals[id].endTime);
    }

    function vote(uint256 id, bool support, uint256 weight) external {
        Proposal storage p = proposals[id];
        require(block.timestamp < p.endTime, "ended");
        require(!voted[id][msg.sender], "voted");
        voted[id][msg.sender] = true;

        if (support) p.voteYes += weight;
        else p.voteNo += weight;

        emit Voted(id, msg.sender, support, weight);
    }

    function queue(uint256 id) external {
        Proposal storage p = proposals[id];
        require(block.timestamp >= p.endTime, "not ended");
        require(!p.queued, "queued");
        require(p.voteYes > p.voteNo, "not passed");

        p.queued = true;
        p.eta = block.timestamp + timelockDelay;

        emit Queued(id, p.eta);
    }

    function execute(uint256 id) external {
        Proposal storage p = proposals[id];
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
