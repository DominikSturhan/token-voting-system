pragma solidity ^0.4.25;

/**
 * @title Controller
 * @author Dominik Sturhan
 * 
 * @notice Certain functions should only be executed by a selected person. 
 *  The controller contract inherits this function and defines who the owner is.
 */
contract Controller {
    
    /// Variables ///
    
    /**
     * @notice Everyone is able to see the address of the 'owner'
     * 
     * @dev The 'owner' could be a person who carries out orders 
     *  on behalf of the shareholders
     */
    address public owner;
    
    /// Modifiers ///
    
    /**
     * @notice Modifier is needed to control access
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    /// Functions ///
    
    /**
     * Constructor function
     * 
     * @notice Startup function to define that the contract creator is 'owner'
     */
    constructor() public {
        owner = msg.sender;
    }
    
    /**
     * changeOwner function
     * 
     * @notice Transfers ownership of the contract
     * @param  _newOwner Address of the new owner
     */
    function changeOwner(
        address _newOwner
    ) public onlyOwner {
        owner = _newOwner;
    }
}
