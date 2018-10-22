pragma solidity ^0.4.25;
import './Controller.sol';
import './VotingStorage.sol';
import './ProposalStorage.sol';

interface ForestToken {
    function getBalanceAt(
        address _owner,
        uint _block
    ) view external returns (uint);
    
    function getTotalSupplyAt(
        uint _block
    ) view external returns (uint);
}

contract VotingMechanism is Controller, ProposalStorage, VotingStorage {
    
    // Voting Rules
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
    // event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    // event Voted(uint proposalID, address voter);
    // event ProposalTallied(uint proposalID, uint yes, uint nay, uint quorum, bool active);
    // event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriodInMinutes, int newMajorityMargin);

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
    }
    
    /// External or public function ///
    
    /**
     * changeToken function
     * 
     * @notice Changes the address of token contract
     * @param newToken Adress of new token contract
     */
    function changeToken (
        address newToken
    ) public onlyOwner {
        token = ForestToken(newToken);
    }

    /**
     * changeVotingRules function
     *
     * Make so that proposals need to be discussed for at least `minutesForDebate/60` hours,
     * have at least `minimumQuorumForProposals` votes, and have 50% + `marginOfVotesForMajority` votes to be executed
     *
     * @param _minimumQuorum how many members must vote on a proposal for it to be executed
     * @param _durationPhaseInMinutes the minimum amount of delay between when a proposal is made and when it can be executed
     */
    function changeVotingRules(
        uint _minimumQuorum,
        uint _durationPhaseInMinutes
    ) public onlyOwner {
        minimumQuorum = _minimumQuorum;
        durationPhaseInMinutes = _durationPhaseInMinutes;

        // emit ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
    }

    /**
     * nnewProposal function
     *
     * @notice Propose to send '__etherAmount' to 'recipient'
     * @param _description Description of job
     */
    function newProposal(
        string _description
    )
        onlyShareholder public returns (uint proposalID)
    {
        Proposal memory proposal;
        
        proposal.description = _description;

        proposal.weightingDate = block.number;
        proposal.startVotingPhase = now;
        proposal.endVotingPhase = now + durationPhaseInMinutes * 1 minutes;
        proposal.startRevealingPhase = now + durationPhaseInMinutes * 1 minutes;
        proposal.endRevealingPhase = now + durationPhaseInMinutes * 2 minutes;
        
        proposal.numberOfVotes = 0;
        proposal.executed = false;
        proposal.proposalPassed = false;
        proposal.result.yea = 0;
        proposal.result.nay = 0;
        
        return addProposal(proposal);
    }

    /**
     * vote function    
     * 
     * @notice Sharehole can cast a vote in support of or against proposal
     * @param _proposalID ID of proposal
     * @param _secret encrypted vote
     */
    function voteOnProposal(
        uint _proposalID,
        bytes32 _secret
    ) public returns (bool){
        Proposal storage proposal = proposals[_proposalID];
        uint balance = token.getBalanceAt(msg.sender, proposal.weightingDate);
        
        require(balance >= 0);
        require(proposal.endVotingPhase > now);
        require(proposal.voted[msg.sender] != true);
        
        Vote memory vote;
        vote.proposalID = _proposalID;
        vote.voter = msg.sender;
        vote.secret = _secret;
        vote.weight = balance;
        vote.endVotingPhase = proposal.endVotingPhase;
        vote.endRevealingPhase = proposal.endRevealingPhase;
        
        proposal.voted[msg.sender] = true;
        
        return addEntry(vote);
    }
    
    /** 
     * revealVote function
     */
    function revealVote(
        uint _proposalID,
        string _salt,
        string _plain
    ) public returns (bool){
        Proposal storage proposal = proposals[_proposalID];
        Vote memory vote = getVote(msg.sender, _proposalID);
        
        require(proposal.startRevealingPhase < now);
        require(proposal.endRevealingPhase > now);
        require(checkEncryption(msg.sender, _proposalID, _salt, _plain));
        
        if(compareStrings(_plain, "yea")) {
            proposal.result.yea += vote.weight;
        } else if(compareStrings(_plain, "nay")) {
            proposal.result.nay += vote.weight; 
        } else {
            return false;
        }
        
        proposal.numberOfVotes += vote.weight;
        
        removeEntry(msg.sender, _proposalID);
        return true;
        
    }
    
    /**
     * executeProposal function
     *
     * Count the votes proposal #`proposalNumber` and execute it if approved
     *
     * @param proposalNumber proposal number
     */
    function executeProposal(uint proposalNumber) public {
        Proposal storage proposal = proposals[proposalNumber];

        require(now > proposal.endRevealingPhase                                          
            && !proposal.executed                                                      
            && proposal.numberOfVotes >= minimumQuorum);                       

        // ...then execute result

        if (proposal.result.yea > proposal.result.nay) {
            // Proposal passed; execute the transaction

            proposal.executed = true; // Avoid recursive calling

            proposal.proposalPassed = true;
        } else {
            // Proposal failed
            proposal.proposalPassed = false;
        }

        // Fire Events
        //emit ProposalTallied(proposalNumber, p.tally.yea, p.tally.nay, p.numberOfVotes, p.proposalPassed);
    }
    
    /**
     * encrypt function
     * 
     * @notice function is used to get hash of two string
     * @param _a First string
     * @param _b Second string
     * @return returns the the encryption as bytes32
     */
    function encrypt(
        string _a, 
        string _b
    ) external pure returns (bytes32){
        return keccak256(abi.encodePacked(_a, _b));
    }    
    /// Internal functions
    
    function compareStrings (
        string a, 
        string b
    ) internal pure returns (bool){
       return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
   }
}
