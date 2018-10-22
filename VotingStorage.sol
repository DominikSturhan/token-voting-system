pragma solidity ^0.4.25;

contract VotingStorage {
    
    struct Vote {
        uint proposalID;
        address voter;
        bytes32 secret;
        uint weight;
        uint endVotingPhase;
        uint endRevealingPhase;
    }
    
    struct ListElement{
        bytes32 prev;
        bytes32 next;
        
        Vote vote;
    }
    
    struct LinkedList{
        uint length;
        bytes32 head;
        bytes32 tail;
        mapping (bytes32 => ListElement) listElements;
    }

    mapping (address => LinkedList) internal lists;

    /**
     * addEntry function
     * 
     * @notice this function adds a new vote to the end the list
     * @param _vote Vote with all information
     * @return true if successful
     */
    function addEntry(
        Vote _vote
    ) internal returns (bool) {
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
        
        return true;
    }
    
    /**
     * getEntry function
     * 
     * @notice The voter can query his casted vote for a proposal
     * @param _voter Address of the voter
     * @param _proposalID ID of the proposal
     * @return All information about the casted vote
     */
    function getEntry(
        address _voter,
        uint _proposalID
    ) external view returns (uint proposalID, address voter, bytes32 secret, uint weight, uint endVotingPhase, uint endRevealingPhase) {
        LinkedList storage list = lists[_voter]; 
        
        bytes32 id = keccak256(abi.encodePacked(_voter, _proposalID));
        Vote memory vote = list.listElements[id].vote;
        
        return (vote.proposalID, vote.voter, vote.secret, vote.weight, vote.endVotingPhase, vote.endRevealingPhase);
    }
    
    function getVote(
        address _voter,
        uint _proposalID
    ) internal view returns (Vote) {
        LinkedList storage list = lists[_voter]; 
        
        bytes32 id = keccak256(abi.encodePacked(_voter, _proposalID));
        return list.listElements[id].vote;
    }
    
    /**
     * removeEntry function
     * 
     * @notice The function removes an entry if the hash of _salt and _vote 
     *  matches the secret
     * @param _voter Address of the voter
     * @param _proposalID ID of the proposal    
     * @return True if successful
     */
    function removeEntry(
        address _voter,
        uint _proposalID
    ) internal returns (bool) {
        LinkedList storage list = lists[_voter];
        
        bytes32 id = keccak256(abi.encodePacked(_voter, _proposalID));
        bytes32 next = list.listElements[id].next;
        bytes32 prev = list.listElements[id].prev;
        
        list.listElements[prev].next = next;
        list.listElements[next].prev = prev;
        
        delete list.listElements[id];
        list.length--;
        
        return true;
    }
    
    function checkEncryption(
        address _voter,
        uint _proposalID,
        string _salt,
        string _vote
    ) internal view returns (bool) {
        LinkedList storage list = lists[_voter];
        
        bytes32 id = keccak256(abi.encodePacked(_voter, _proposalID));
        Vote memory vote = list.listElements[id].vote;
        
        return keccak256(abi.encodePacked(_salt, _vote)) == vote.secret;
    }
        

    /**
     * getOpenIDs function
     * 
     * @notice function displays the user which IDs are still open
     * @return a string like "IDs: ..."
     */
    function getOpenIDs() external view returns (string ids){
        LinkedList storage list = lists[msg.sender];
        bytes32 element = list.head;
        
        ids = "IDs:";
        
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
     * appendUintToString function
     * 
     * @notice function is an internal helper for getOpenIDs
     * @param _str Current string
     * @param _space Space string
     * @param _int Uint to be appended
     * @return new string with space and uint appended
     */
    function appendUintToString(
        string _str,
        string _space,
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
        bytes memory str = bytes(_str);
        bytes memory space = bytes(_space);
        
        // Generate new bytes array
        bytes memory s = new bytes(str.length + space.length + actualLength);
        
        // Insert above arrays into new array
        // Insert current string
        uint j;
        for (j = 0; j < str.length; j++) {
            s[j] = str[j];
        }
        
        // Insert space string
        for (j = 0; j < space.length; j++) {
            s[str.length + j] = space[j];
        }
        
        // Insert uint
        for (j = 0; j < actualLength; j++) {
            s[str.length + space.length + j] = reversed[actualLength - 1 - j];
        }
        
        return string(s);
    }
}
