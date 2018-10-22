pragma solidity ^0.4.25;

contract ProposalStorage {
    
    struct Result {
        // Counters
        uint yea;
        uint nay;
    }
    
    struct Proposal {
        // Information about the purpose of the proposal
        string description;
        
        // Dates
        uint weightingDate;
        uint startVotingPhase;
        uint endVotingPhase;
        uint startRevealingPhase;
        uint endRevealingPhase;
        
        // Internal helper
        uint numberOfVotes;
        bool executed;
        bool proposalPassed;
        
        // Storages
        mapping (address => bool) voted;
        Result result;
    }
    
    Proposal[] public proposals;
    
    function addProposal(
        Proposal _proposal
    ) internal returns (uint proposalID) {
        proposalID = proposals.length++;
        proposals[proposalID] = _proposal;
        
        return proposalID;
    }
}
