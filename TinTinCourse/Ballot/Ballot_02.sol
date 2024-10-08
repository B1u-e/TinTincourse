/*
基于当前提供的 Ballot 合约,进行修改和扩展，设置投票权重功能并确保其功能正确性。

功能描述: 允许投票权重的设置。投票权重可以由合约所有者设置，默认每个选民的权重为 1。

要求:

添加一个函数 setVoterWeight(address voter, uint weight)，允许合约所有者为某个选民设置特定的投票权重，并添加时间限制。

确保只有合约所有者（chairperson）可以调用此函数。
*/
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    struct Voter {
        uint256 weight;
        bool voted;
        address delegate;
        uint256 vote;
    }

    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }

    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    // New state variables for time limits on setting voter weights
    uint256 public weightSettingStartTime;
    uint256 public weightSettingEndTime;

    constructor(
        bytes32[] memory proposalNames,
        uint256 startTimeDelay,
        uint256 duration
    ) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // Initialize proposals
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }

        // Set time limits for setting voter weights
        weightSettingStartTime = block.timestamp + startTimeDelay; // Starts after startTimeDelay
        weightSettingEndTime = block.timestamp + duration; // Ends after the specified duration
    }

    function giveRightToVote(address voter) external {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(!voters[voter].voted, "The voter already voted.");
        require(
            voters[voter].weight == 0,
            "The voter already has voting rights."
        );

        voters[voter].weight = 1;
    }

    function setVoterWeight(address voter, uint256 weight) external {
        require(
            msg.sender == chairperson,
            "Only chairperson can set voter weight."
        );
        require(
            block.timestamp >= weightSettingStartTime &&
                block.timestamp <= weightSettingEndTime,
            "Weight setting is not allowed at this time."
        );

        require(
            voters[voter].weight != 0,
            "The voter does not have voting rights."
        );

        voters[voter].weight = weight;
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote.");
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = voters[to];
        require(
            delegate_.weight >= 1,
            "Selected delegate does not have voting rights."
        );
        sender.voted = true;
        sender.delegate = to;
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint256 proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote.");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}