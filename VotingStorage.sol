pragma solidity ^0.4.25;

/**
 * @title Voting Storage
 * @author Dominik Sturhan
 * 
 * @notice This contract stores all votes cast. Once a vote is revealed, it 
 *  will be deleted from the storage.
 */
contract VotingStorage {
    
    /// Structs ///
    
    /**
     * @dev The 'Vote' describes the structure in which all information about 
     *  the vote will be stored
     */
    struct Vote {
        uint proposalID;
        address voter;
        bytes32 secret;
        uint weight;
        uint endVoting;
        uint endRevealing;
    }
    
    /**
     * @dev The 'ListElement' stores a 'vote'. It also knows the 'prev' and 
     *  'next' element
     */
    struct ListElement{
        bytes32 prev;
        bytes32 next;
        
        Vote vote;
    }
    
    /**
     * @dev The 'Vote' will be stored in a circular double linked list. Every 
     *  list knows it's head and tail.
     */
    struct LinkedList{
        uint length;
        bytes32 head;
        bytes32 tail;
        mapping (bytes32 => ListElement) listElements;
    }
    
    /// Variables ///
    
    /**
     * @dev Every voter has his own list. All of them are stored in the 
     *  map 'lists'.
     */
    mapping (address => LinkedList) internal lists;

    /// Functions ///

    /**
     * getOpenIDs function
     * 
     * @notice Query all unreaveled votes of the sender
     * 
     * @return A string like "There are unreaveled votes for the following 
     *  proposals: ..."
     */
    function getOpenIDs() external view returns (string){
        LinkedList storage list = lists[msg.sender];
        bytes32 element = list.head;
        
        string memory ids = "There are unreaveled votes for the following proposals:";
        
        // Loop that analyzes the 'list'
        uint length = list.length;
        uint pointer = 1;
        while(pointer <= length){
            bytes32 next = list.listElements[element].next;
            Vote memory vote = list.listElements[next].vote;
            
            ids = appendUintToString(ids, " ", vote.proposalID);
            
            element = next;
            pointer++;
        }
        return ids;
    }

    /**
     * queryVote function
     * 
     * @notice The voter can query his casted vote for a proposal
     * 
     * @param _proposalID ID of the proposal
     * @return All information about the casted vote
     */
    function queryVote(
        uint _proposalID
    ) external view returns (bytes32 Secret, uint Weight, 
        uint EndOfVotingPhase, uint EndOfRevealingPhase) {
            
        Vote memory vote = getVote(msg.sender, _proposalID);
        
        return (vote.secret, vote.weight, vote.endVoting, 
            vote.endRevealing);
    }
    
    /**
     * deleteVote function
     * 
     * @notice Delete a vote of the list after the revealing period
     * 
     * @param _proposalID ID of the proposal
     */
    function deleteVote(
        uint _proposalID
    ) public {
        LinkedList storage list = lists[msg.sender];
        
        bytes32 id = keccak256(abi.encodePacked(msg.sender, _proposalID));
        
        // Revealing period needs to be ended
        require(list.listElements[id].vote.endRevealing < now);
        
        bytes32 next = list.listElements[id].next;
        bytes32 prev = list.listElements[id].prev;
        
        list.listElements[prev].next = next;
        list.listElements[next].prev = prev;
        
        if(id==list.tail) list.tail = prev;
        
        delete list.listElements[id];
        list.length--;
    }
    
    /**
     * isAllowedToVote function
     * 
     * @notice Checks if the voter's right to vote is blocked
     * 
     * @param _voter Address of the voter
     * @return True if the voter is allowed to voter
     */
    function isAllowedToVote(
        address _voter
    ) internal view returns (bool){
        LinkedList storage list = lists[_voter];
        bytes32 element = list.head;
        
        // If there is no entry, the voter is allowed to vote
        if (list.length == 0) return true;
        
        // If there are entries and the end of their voting phase is in the 
        //  past, the voter is not allowed to vote
        uint length = list.length;
        uint pointer = 1;
        while(pointer <= length){
            bytes32 next = list.listElements[element].next;
            Vote memory vote = list.listElements[next].vote;
            
            if (now > vote.endVoting) return false;
            
            element = next;
            pointer++;
        }
        
        // Else return true, the voter is allowed to vote 
        return true;
    }
    
    /**
     * storeVote function
     * 
     * @notice Add a new vote to end of the list
     * 
     * @param _vote Structure with all information about the casted vote
     */
    function storeVote(
        Vote _vote
    ) internal {
        LinkedList storage list = lists[_vote.voter];
        
        bytes32 id = keccak256(abi.encodePacked(_vote.voter, _vote.proposalID));
        
        if(list.length == 0) {
            list.listElements[id] = ListElement(list.head, list.head, _vote);
            
            list.listElements[list.head].next = id;
            list.listElements[list.head].prev = id;
        } else {
            list.listElements[id] = ListElement(list.tail, list.head, _vote);
            
            list.listElements[list.tail].next = id;
            list.listElements[list.head].prev = id;
        }
        
        list.tail = id;
        list.length++;
    }
    
    /**
     * getVote function
     * 
     * @notice Query a casted vote 
     * 
     * @param _voter Address of the voter
     * @param _proposalID The ID of the proposal
     * @return The casted vote
     */
    function getVote(
        address _voter,
        uint _proposalID
    ) internal view returns (Vote) {
        LinkedList storage list = lists[_voter]; 
        
        bytes32 id = keccak256(abi.encodePacked(_voter, _proposalID));
        return list.listElements[id].vote;
    }
    
    /**
     * checkSecret function
     * 
     * @notice Check if the entered data matches the secret.
     * 
     * @param _voter Address of the voter
     * @param _proposalID The ID of the proposal
     * @param _salt Salt value to generate the hash 
     * @param _plain The decrypted vote
     * @return True if the hash of the entered data matches the secret
     */
    function checkSecret(
        address _voter,
        uint _proposalID,
        string _salt,
        string _plain
    ) internal view returns (bool) {
        LinkedList storage list = lists[_voter];
        
        bytes32 id = keccak256(abi.encodePacked(_voter, _proposalID));
        Vote memory vote = list.listElements[id].vote;
        
        return keccak256(abi.encodePacked(_salt, _plain)) == vote.secret;
    }
   
   /**
     * removeVote function
     * 
     * @notice Remove a vote of the list
     * 
     * @param _voter Address of the voter
     * @param _proposalID ID of the proposal
     */
    function removeVote(
        address _voter,
        uint _proposalID
    ) internal {
        LinkedList storage list = lists[_voter];
        
        bytes32 id = keccak256(abi.encodePacked(_voter, _proposalID));
        bytes32 next = list.listElements[id].next;
        bytes32 prev = list.listElements[id].prev;
        
        list.listElements[prev].next = next;
        list.listElements[next].prev = prev;
        
        if(id==list.tail) list.tail = prev;
        
        delete list.listElements[id];
        list.length--;
    }
    
    /**
     * appendUintToString function
     * 
     * @notice Internal helper for getOpenIDs
     * 
     * @param _strA Current string
     * @param _strB Space string
     * @param _int Uint to be appended
     * @return new string with space and uint appended
     */
    function appendUintToString(
        string _strA,
        string _strB,
        uint _int
    ) internal pure returns (string) {
        
        // Transform uint into bytes array
        bytes memory reversed = new bytes(100);
        uint actualLength = 0;
        while (_int != 0) {
            uint remainder = _int % 10;
            _int = _int / 10;
            reversed[actualLength++] = byte(48 + remainder);
        }
        
        // Transform string into bytes array
        bytes memory strA = bytes(_strA);
        bytes memory strB = bytes(_strB);
        
        // Generate new bytes array
        bytes memory s = new bytes(strA.length + strB.length + actualLength);
        
        // Insert above arrays into new array
        // Insert current string
        uint j;
        for (j = 0; j < strA.length; j++) {
            s[j] = strA[j];
        }
        
        // Insert space string
        for (j = 0; j < strB.length; j++) {
            s[strA.length + j] = strB[j];
        }
        
        // Insert uint
        for (j = 0; j < actualLength; j++) {
            s[strA.length + strB.length + j] = reversed[actualLength - 1 - j];
        }
        
        return string(s);
    }
}
