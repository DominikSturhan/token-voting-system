pragma solidity ^0.4.25;

contract managingVotingRights {
    
    struct ListElement{
        bytes32 next;
        bytes32 prev;
        uint value;
    }
    
    struct LinkedList{
        uint length;
        bytes32 head;
        bytes32 tail;
        mapping (bytes32 => ListElement) listElements;
    }

    mapping (address => LinkedList) internal lists;

    function addEntry(uint _id, uint _value) public {
        LinkedList storage list = lists[msg.sender];
        
        bytes32 id = keccak256(msg.sender, _id);
        
        if(list.tail == 0) {
            list.listElements[id] = ListElement(list.head, list.head, _value);
            
            list.listElements[list.head].next = id;
            list.listElements[list.head].prev = id;
        } else {
            list.listElements[id] = ListElement(list.head, list.tail, _value);
            
            list.listElements[list.tail].next = id;
            list.listElements[list.head].prev = id;
        }
        
        list.tail = id;
        list.length++;
    }
    
    function getEntry(uint _id) public view returns (uint prevValue, uint nextValue, uint value) {
        LinkedList storage list = lists[msg.sender]; 
        bytes32 id = keccak256(msg.sender, _id);
        bytes32 next = list.listElements[id].next;
        bytes32 prev = list.listElements[id].prev;
        
        return (list.listElements[prev].value, list.listElements[next].value, list.listElements[id].value);
    }
    
    function removeEntry(uint _id) public {
        LinkedList storage list = lists[msg.sender];
        
        bytes32 id = keccak256(msg.sender, _id);
        bytes32 next = list.listElements[id].next;
        bytes32 prev = list.listElements[id].prev;
        
        list.listElements[prev].next = next;
        list.listElements[next].prev = prev;
        
        delete list.listElements[id];
    }

}
