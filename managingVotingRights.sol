pragma solidity ^0.4.25;

contract managingVotingRights {
    
    struct ListElement{
        bytes32 prev;
        bytes32 next;
        
        uint proposalID;
        bytes32 secret;
    }
    
    struct LinkedList{
        uint length;
        bytes32 head;
        bytes32 tail;
        mapping (bytes32 => ListElement) listElements;
    }

    mapping (address => LinkedList) internal lists;

    function addEntry(
        uint _id, 
        bytes32 _secret
    ) public {
        LinkedList storage list = lists[msg.sender];
        
        bytes32 id = keccak256(abi.encodePacked(msg.sender, _id));
        
        if(list.length == 0) {
            list.listElements[id] = ListElement(list.head, list.head, _id, _secret);
            
            list.listElements[list.head].next = id;
            list.listElements[list.head].prev = id;
        } else {
            list.listElements[id] = ListElement(list.tail, list.head, _id, _secret);
            
            list.listElements[list.tail].next = id;
            list.listElements[list.head].prev = id;
        }
        
        list.tail = id;
        list.length++;
    }
    
    function getEntry(
        uint _id
    ) public view returns (uint prevID, uint nextID, uint proposalID, bytes32 secret) {
        LinkedList storage list = lists[msg.sender]; 
        
        bytes32 id = keccak256(abi.encodePacked(msg.sender, _id));
        bytes32 next = list.listElements[id].next;
        bytes32 prev = list.listElements[id].prev;
        
        return (list.listElements[prev].proposalID, list.listElements[next].proposalID, list.listElements[id].proposalID, list.listElements[id].secret);
    }
    
    function removeEntry(
        uint _id
    ) public {
        LinkedList storage list = lists[msg.sender];
        
        bytes32 id = keccak256(abi.encodePacked(msg.sender, _id));
        bytes32 next = list.listElements[id].next;
        bytes32 prev = list.listElements[id].prev;
        
        list.listElements[prev].next = next;
        list.listElements[next].prev = prev;
        
        delete list.listElements[id];
        list.length--;
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
            ids = appendUintToString(ids, " ", list.listElements[next].proposalID);
            
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

}
