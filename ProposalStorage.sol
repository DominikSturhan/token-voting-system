pragma solidity ^0.4.25;

/**
 * @title Proposal Storage
 * @author Dominik Sturhan
 * 
 * @notice This contract stores all proposals.
 */
contract ProposalStorage {
    
    /**
     * @notice This structure defines what a proposal is. 
     * 
     * @dev The person creating the new proposal can only add a description. 
     *  The other variables are set by the voting mechanisms.
     */
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
        mapping (address => bool) voted;
        uint yea;
        uint nay;
    }
    
    // Internal storage for proposals
    mapping (uint => Proposal) internal proposals;
    // Counter for the ID
    uint internal currentID;
    
    /// External functions ///
    
    /**
     * getProposal function
     * 
     * @notice Query the proposal belonging to the entered ID
     * 
     * @param _proposalID ID of the proposal
     * @return All the import information about the proposal
     */
    function getProposal(
        uint _proposalID
    ) external view returns (string Description, string Status, 
        uint WeightingDate, bool Passed, uint YEA, uint NAY){
            
        Proposal memory proposal = proposals[_proposalID];
        string memory status;
        
        if(now >= proposal.startVotingPhase 
            && now < proposal.endVotingPhase){
             
            status = "in voting phase";
        } else if (now >= proposal.startRevealingPhase 
            && now < proposal.endRevealingPhase){
                
            status = "in revealing phase";
        } else if (now >= proposal.endRevealingPhase && !proposal.executed){
            status = "wating for execution";
        } else {
            status = "closed";
        }
        
        return (proposal.description, status, proposal.weightingDate, 
            proposal.proposalPassed, proposal.yea, proposal.nay);
    }
    
    /// Internal functions ///
    
    /**
     * addProposal function
     * 
     * @notice Internal function to add a proposal to the storage
     * @param _proposal The proposal to be added
     * @return The ID of the added proposal
     */
    function addProposal(
        Proposal _proposal
    ) internal returns (uint proposalID) {
        proposalID = currentID;
        proposals[proposalID] = _proposal;
        currentID++;
        
        return proposalID;
    }
}
