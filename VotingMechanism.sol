pragma solidity ^0.4.25;
import './Controller.sol';
import './VotingStorage.sol';
import './ProposalStorage.sol';

/**
 * @notice Interface is needed to query the historical balances
 */
interface ForestToken {
    function getBalanceAt(
        address _owner,
        uint _block
    ) view external returns (uint);
    
    function getTotalSupply(
    ) external view returns (uint);
    
    function getTotalSupplyAt(
        uint _block
    ) view external returns (uint);
}

/**
 * @title Voting Mechanism
 * @author Dominik Sturhan
 * 
 * @notice This contract is the voting mechanism. 
 * 
 * @dev It inherits from the contracts Controller, ProposalStorage and 
 *  VotingStorage. If ProposalStorage and VotingStorage were stand-alone 
 *  contracts, it would result in unnecessary transactions between them.
 */
contract VotingMechanism is Controller, ProposalStorage, VotingStorage {
    
    /**
     * These variables represent the voting rules. 
     * 'minimumQuorum' has a value between 1 and 100. It describes the required 
     *  percentage of the total supply, that a proposal may be executed at all
     * 'durationPhaseInMinutes' describes the duration of the voting and 
     *  revealing phase in minutes
     */
    uint public minimumQuorum;
    uint public durationPhaseInMinutes;
    
    // Reference to the ForestToken
    ForestToken token;
    
    /**
     * @notice Modifier is needed to control access
     */
    modifier onlyShareholder {
        require(token.getBalanceAt(msg.sender, block.number) >= 0);
        _;
    }

    // This generates public events on the blockchain that will notify clients
    event ChangeOfRules(uint newMinimumQuorum, uint newDurationPhaseInMinutes);
    event Voted(uint proposalID, address voter);
    event Revealed(uint proposalID, address voter);
    event ProposalTallied(uint proposalID, bool proposalPassed, 
        uint YEA, uint NAY);
   
    /**
     * Constructor function
     */
    constructor (
        uint _minimumQuorum,
        uint _durationPhaseInMinutes,
        address _token
    )  payable public {
        changeVotingRules(_minimumQuorum, _durationPhaseInMinutes);
        changeToken(_token);
        
        currentID = 1;
    }
    
    /// Public function ///
    
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
        token = ForestToken(newToken);
    }

    /**
     * changeVotingRules function
     *
     * @notice Change the 'minimumQuorum' and 'durationPhaseInMinutes'
     *
     * @param _minimumQuorum Required percentage of the total supply, that a 
     *  proposal may be executed at all
     * @param _durationPhaseInMinutes The duration of the voting and 
     *  revealing phase in minutes
     */
    function changeVotingRules(
        uint _minimumQuorum,
        uint _durationPhaseInMinutes
    ) public onlyOwner {
        // 'minimumQuorum' has a value between 1 and 100. 
        require(_minimumQuorum >= 1 && _minimumQuorum <= 100);
        
        minimumQuorum = _minimumQuorum;
        durationPhaseInMinutes = _durationPhaseInMinutes;
        
        // Fire event
        emit ChangeOfRules(minimumQuorum, durationPhaseInMinutes);
    }

    /**
     * newProposal function
     *
     * @notice Create a new proposal
     * 
     * @param _description Description of the proposal
     * @return True if successful
     */
    function newProposal(
        string _description
    )
    public onlyShareholder returns (uint proposalID)
    {
        // Initialize a new proposal
        Proposal memory proposal;
        
        proposal.description = _description;

        proposal.weightingDate = block.number;
        proposal.startVotingPhase = now;
        proposal.endVotingPhase = now + durationPhaseInMinutes * 1 minutes;
        proposal.startRevealingPhase = now + durationPhaseInMinutes * 1 minutes;
        proposal.endRevealingPhase = now + durationPhaseInMinutes * 2 minutes;
        
        proposal.numberOfSecretVotes = 0;
        proposal.numberOfRevealedVotes = 0;
        proposal.numberOfTokens = 0;
        proposal.minQuorum = (1/minimumQuorum) * token.getTotalSupply();
        proposal.executed = false;
        proposal.proposalPassed = false;
        proposal.yea = 0;
        proposal.nay = 0;
        
        return addProposal(proposal);
    }

    /**
     * vote function    
     * 
     * @notice Shareholder can cast a vote in support of or against proposal
     * 
     * @param _proposalID ID of proposal
     * @param _secret encrypted vote
     * @return True if successful
     */
    function voteOnProposal(
        uint _proposalID,
        bytes32 _secret
    ) public returns (bool){
        Proposal storage proposal = proposals[_proposalID];
        uint balance = token.getBalanceAt(msg.sender, proposal.weightingDate);
        
        // The voter needs to be a shareholder 
        require(balance > 0);
        // The proposal must be in the voting phase
        require(now > proposal.startVotingPhase 
            && now < proposal.endVotingPhase);
        // Check if the voter has not already voted
        require(proposal.voted[msg.sender] != true);
        // Check if the voter's right to vote is blocked'
        require(isAllowedToVote(msg.sender));
        
        // Initialize a new vote
        Vote memory vote;
        vote.proposalID = _proposalID;
        vote.voter = msg.sender;
        vote.secret = _secret;
        vote.weight = balance;
        vote.endVotingPhase = proposal.endVotingPhase;
        vote.endRevealingPhase = proposal.endRevealingPhase;
        
        addEntry(vote);
        
        proposal.voted[msg.sender] = true;
        proposal.numberOfSecretVotes++;
        
        // Fire event
        emit Voted(_proposalID, msg.sender);
        return true;
    }
    
    /** 
     * revealVote function
     * 
     * @notice Shareholder can reveal his casted vote
     * 
     * @param _proposalID ID of proposal
     * @param _salt Salt value used to encrypt
     * @param _plain Decrypted vote
     * @return True if successful
     */
    function revealVote(
        uint _proposalID,
        string _salt,
        string _plain
    ) public returns (bool){
        Proposal storage proposal = proposals[_proposalID];
        Vote memory vote = _getVote(msg.sender, _proposalID);
        
        // The proposal must be in the revealing phase
        require(proposal.startRevealingPhase < now 
            && proposal.endRevealingPhase > now);
        // Check if the hash of the entered data matches with the secret
        require(checkEncryption(msg.sender, _proposalID, _salt, _plain));
        
        // Tally the vote
        if(compareStrings(_plain, "yea")) {
            proposal.yea += vote.weight;
        } else if(compareStrings(_plain, "nay")) {
            proposal.nay += vote.weight; 
        } else {
            return false;
        }
        
        proposal.numberOfTokens += vote.weight;
        proposal.numberOfRevealedVotes++;
        
        removeEntry(msg.sender, _proposalID);
        // Fire event
        emit Revealed(_proposalID, msg.sender);
        return true;
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
        require(now > proposal.endRevealingPhase);   
        // Proposal should not already be executed
        require(!proposal.executed); 
        // The quorum must be reached
        require(proposal.numberOfTokens >= proposal.minQuorum);                       

        if (proposal.yea > proposal.nay) {
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
            proposal.yea, proposal.nay);
    }
    
    /// Internal functions
    
    function compareStrings (
        string a, 
        string b
    ) internal pure returns (bool){
       return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
   }
}
