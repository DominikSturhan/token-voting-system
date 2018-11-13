pragma solidity ^0.4.25;

/**
 * @title Proposal Storage
 * @author Dominik Sturhan
 * 
 * @notice This contract stores all proposals.
 */
contract ProposalStorage {
    
    /// Structs ///
    
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
        uint recordDate;
        uint startVoting;
        uint endVoting;
        uint startRevealing;
        uint endRevealing;
        
        // Internal helper
        uint numberOfSecretVotes;
        uint numberOfRevealedVotes;
        uint numberOfTokens;
        uint minQuorum;
        bool executed;
        bool proposalPassed;
        mapping (address => bool) voted;
        uint yes;
        uint no;
    }
    
    /// Variables ///
    
    // Internal storage for proposals
    mapping (uint => Proposal) internal proposals;
    // Counter for the ID
    uint internal currentID;
    
    /// Events ///
    
    // This generates a public event on the blockchain that will notify clients
    event ProposalSubmitted(uint proposalID, string description, uint recordDate, 
        uint endVoting, uint endRevealing);
    
    /// Functions ///
    
    /**
     * queryProposal function
     * 
     * @notice Query the proposal belonging to the entered ID
     * 
     * @param _proposalID ID of the proposal
     * @return All the import information about the proposal
     */
    function queryProposal(
        uint _proposalID
    ) public view returns (string Description, string Status, 
        uint RecordDate, bool Passed, uint Yes, uint No){
            
        Proposal memory proposal = proposals[_proposalID];
        string memory status;
        
        if(now >= proposal.startVoting 
            && now < proposal.endVoting){
             
            status = "in voting phase";
        } else if (now >= proposal.startRevealing 
            && now < proposal.endRevealing){
                
            status = "in revealing phase";
        } else if (now >= proposal.endRevealing && !proposal.executed){
            status = "wating for execution";
        } else {
            status = "closed";
        }
        
        return (proposal.description, status, proposal.recordDate, 
            proposal.proposalPassed, proposal.yes, proposal.no);
    }

    /**
     * storeProposal function
     * 
     * @notice Internal function to add a proposal to the storage
     * 
     * @param _proposal The proposal to be added
     * @return The ID of the added proposal
     */
    function storeProposal(
        Proposal _proposal
    ) internal returns (uint proposalID) {

        proposalID = currentID;
        proposals[proposalID] = _proposal;
        currentID++;
        
        // Fire event
        emit ProposalSubmitted(proposalID, _proposal.description, 
            _proposal.recordDate, _proposal.endVoting, 
            _proposal.endRevealing);
        return proposalID;
    }
}
