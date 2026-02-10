// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";


contract BaseGovernor is
    Governor,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    uint48 private _votingDelayBlocks = 1;      // educational
    uint32 private _votingPeriodBlocks = 45818; // ~1 week on 13s blocks, adjust for Base

    constructor(IVotes token, TimelockController timelock)
        Governor("BaseGovernor")
        GovernorVotes(token)
        GovernorVotesQuorumFraction(4) // 4% quorum
        GovernorTimelockControl(timelock)
    {}

    function votingDelay() public view override returns (uint256) {
        return _votingDelayBlocks;
    }

    function votingPeriod() public view override returns (uint256) {
        return _votingPeriodBlocks;
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 10_000e18; // educational threshold
    }

    // required overrides
    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)


    }
}
