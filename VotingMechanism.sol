pragma solidity ^0.4.25;
import './Controller.sol';
import './VotingStorage.sol';
import './ProposalStorage.sol';
import './Token.sol';

/**
 * @title Voting Mechanism
 * @author Dominik Sturhan
 * 
 * @notice This contract is the voting mechanism. 
 * 
 * @dev It inherits from the contracts Controller, ProposalStorage and 
 *  VotingStorage. If ProposalStorage and VotingStorage were stand-alone 
 *  contracts, the transfer of struct types would be problematic.
 */
contract VotingMechanism is Controller, ProposalStorage, VotingStorage {
    
    /// Variables ///
    
    /**
     * These variables represent the voting rules. 
     * 'minimumQuorum' has a value between 1 and 100. It describes the required 
     *  percentage of the total supply, that a proposal may be executed at all
     * 'durationInMinutes' describes the duration of the voting and 
     *  revealing period in minutes
     */
    uint public minimumQuorum;
    uint public durationInMinutes;
    
    /// References ///
    
    // Reference to the Token
    Token token;
    
    /// Modifiers ///
    
    /**
     * @notice Modifiers are needed to control access
     */
    modifier onlyShareholder {
        require(token.getBalanceAt(msg.sender, block.number) >= 0);
        _;
    }
    
    modifier onlyAllowedShareholder(uint _proposalID) {
        Proposal storage proposal = proposals[_proposalID];
        uint balance = token.getBalanceAt(msg.sender, proposal.recordDate);
        
        // The voter needs to be a shareholder 
        require(balance > 0);
        // Check if the voter has not already voted
        require(proposal.voted[msg.sender] != true);
        // Check if the voter's right to vote is blocked'
        require(isAllowedToVote(msg.sender));
        
        _;
    }
    
    /// Events ///

    // This generates public events on the blockchain that will notify clients
    event ChangeOfRules(uint newMinimumQuorum, uint newDurationInMinutes);
    event Voted(uint proposalID, address voter);
    event Revealed(uint proposalID, address voter);
    event ProposalTallied(uint proposalID, bool proposalPassed, 
        uint Yes, uint No);
    event ProposalInvalid(uint proposalID);
    
    /// Functions ///
   
    /**
     * Constructor function
     */
    constructor (
        uint _minimumQuorum,
        uint _durationInMinutes
    ) public {
        changeVotingRules(_minimumQuorum, _durationInMinutes);
        currentID = 1;
    }

    /**
     * changeVotingRules function
     *
     * @notice Change the 'minimumQuorum' and 'durationPhaseInMinutes'
     *
     * @param _minimumQuorum Required percentage of the total supply, that a 
     *  proposal may be executed at all
     * @param _durationInMinutes The duration of the voting and 
     *  revealing phase in minutes
     */
    function changeVotingRules(
        uint _minimumQuorum,
        uint _durationInMinutes
    ) public onlyOwner {
        // 'minimumQuorum' has a value between 1 and 100. 
        require(_minimumQuorum >= 1 && _minimumQuorum <= 100);
        
        minimumQuorum = _minimumQuorum;
        durationInMinutes = _durationInMinutes;
        
        // Fire event
        emit ChangeOfRules(minimumQuorum, durationInMinutes);
    }
    
    /**
     * changeToken function
     * 
     * @notice Changes the address of token contract
     * 
     * @param newToken Address of new token contract
     */
    function changeToken (
        address newToken
    ) public onlyOwner {
        token = Token(newToken);
    }

    /**
     * generateSecret function
     * 
     * @notice Function is used to get hash of two string
     * 
     * @dev The voter can generate his secret with this function and it is used
     *  as an internal helper to check the encryption
     * 
     * @param _salt First string
     * @param _plain Second string
     * @return hash
     */
    function generateSecret(
        string _salt, 
        string _plain
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_salt, _plain));
    } 
    
    /**
     * submitProposal function
     *
     * @notice Create a new proposal
     * 
     * @param _description Description of the proposal
     */
    function submitProposal(
        string _description
    ) public onlyShareholder returns (uint proposalID) {
        // Initialize a new proposal
        Proposal memory proposal;
        
        proposal.description = _description;

        proposal.recordDate = block.number;
        proposal.startVoting = now;
        proposal.endVoting = now + durationInMinutes * 1 minutes;
        proposal.startRevealing = now + durationInMinutes * 1 minutes;
        proposal.endRevealing = now + durationInMinutes * 2 minutes;
        
        proposal.numberOfSecretVotes = 0;
        proposal.numberOfRevealedVotes = 0;
        proposal.numberOfTokens = 0;
        proposal.minQuorum = (1/minimumQuorum) * token.getTotalSupply();
        proposal.executed = false;
        proposal.proposalPassed = false;
        proposal.yes = 0;
        proposal.no = 0;
        
        return storeProposal(proposal);
    }

    /**
     * submitVote function    
     * 
     * @notice Shareholder can cast a vote in support of or against proposal
     * 
     * @param _proposalID ID of proposal
     * @param _secret encrypted vote
     */
    function submitVote(
        uint _proposalID,
        bytes32 _secret
    ) public onlyAllowedShareholder(_proposalID){
        Proposal storage proposal = proposals[_proposalID];
        uint balance = token.getBalanceAt(msg.sender, proposal.recordDate);
        
        require(now > proposal.startVoting 
            && now < proposal.endVoting);

        // Initialize a new vote
        Vote memory vote;
        vote.proposalID = _proposalID;
        vote.voter = msg.sender;
        vote.secret = _secret;
        vote.weight = balance;
        vote.endVoting = proposal.endVoting;
        vote.endRevealing = proposal.endRevealing;
        
        storeVote(vote);
        
        proposal.voted[msg.sender] = true;
        proposal.numberOfSecretVotes++;
        
        // Fire event
        emit Voted(_proposalID, msg.sender);
    }
    
    /** 
     * revealVote function
     * 
     * @notice Shareholder can reveal his casted vote
     * 
     * @param _proposalID ID of proposal
     * @param _salt Salt value used to encrypt
     * @param _plain Decrypted vote
     */
    function revealVote(
        uint _proposalID,
        string _salt,
        string _plain
    ) public {
        Proposal storage proposal = proposals[_proposalID];
        Vote memory vote = getVote(msg.sender, _proposalID);
        
        // The proposal must be in the revealing phase
        require(proposal.startRevealing < now 
            && proposal.endRevealing > now);
        // Check if the hash of the entered data matches with the secret
        require(checkSecret(msg.sender, _proposalID, _salt, _plain));
        
        // Tally the vote
        if(compareStrings(_plain, "yes")) {
            proposal.yes += vote.weight;
        } else if(compareStrings(_plain, "no")) {
            proposal.no += vote.weight; 
        } else {
             require(false);
        }
        
        proposal.numberOfTokens += vote.weight;
        proposal.numberOfRevealedVotes++;
        
        removeVote(msg.sender, _proposalID);
        // Fire event
        emit Revealed(_proposalID, msg.sender);
    }
    
    /**
     * executeProposal function
     *
     * @notice Execute it if approved
     *
     * @param _proposalID ID of proposal
     */
    function executeProposal(
        uint _proposalID
    ) public {
        Proposal storage proposal = proposals[_proposalID];

        // Revealing phase must be closed
        require(now > proposal.endRevealing);   
        // Proposal should not already be executed
        require(!proposal.executed); 
        
        proposal.executed = true;
        
        // To be valid, quorum must be reached
        if(proposal.numberOfTokens >= proposal.minQuorum){
            
            if (proposal.yes > proposal.no) {
                // Proposal passed
                proposal.executed = true;
                proposal.proposalPassed = true;
            } else {
                // Proposal failed
                proposal.executed = true;
                proposal.proposalPassed = false;
            }  
            // Fire Events
            emit ProposalTallied(_proposalID, proposal.proposalPassed, 
                proposal.yes, proposal.no);
        } else {
            emit ProposalInvalid(_proposalID);
        }
    }
    
    function compareStrings (
        string a, 
        string b
    ) internal pure returns (bool){
       return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
   }
}
