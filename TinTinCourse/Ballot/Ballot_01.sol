/*
基于当前提供的 Ballot 合约,进行修改和扩展，添加时间限制功能并确保其功能正确性。

功能描述: 为投票过程添加时间限制。设置一个开始时间和结束时间来控制投票的时间窗口。用户只能在投票周期内进行投票。

要求:

在合约中添加两个新的状态变量 startTime 和 endTime，用于表示投票的开始时间和结束时间。

在构造函数中初始化这些时间变量。

修改 vote 函数，确保用户只能在时间窗口内投票。如果不在时间窗口内投票，应该抛出错误。
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

    // New state variables for voting time limits
    uint256 public startTime;
    uint256 public endTime;

    constructor(
        bytes32[] memory proposalNames,
        uint256 startTimeDelay, // delay in seconds
        uint256 duration // duration in seconds
    ) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // Initialize proposals
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }

        // Set voting time limits
        startTime = block.timestamp + startTimeDelay; // Voting starts after startTimeDelay
        endTime = block.timestamp + duration; // Voting ends after the specified duration
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
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Voting is not allowed at this time."
        );

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