pragma solidity ^0.4.25;

/**
 * @title Controller
 * @author Dominik Sturhan
 * 
 * @notice This contract allows the owner of the token and the voting contract
 *  to controll the access
 */
contract Controller {
    
    /// Variables ///
    
    /**
     * @notice Everyone is able to see the address of the 'owner'
     * 
     * @dev The 'owner' could be a person who carries out orders on 
     *  behalf of the shareholders
     */
    address public owner;
    
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
     * transferOwnership function
     * 
     * @notice Transfers ownership of the contract
     * @param  _newOwner Address of the new owner
     */
    function transferOwnership(
        address _newOwner
    ) public onlyOwner {
        owner = _newOwner;
    }
    
    /// Modifier ///
    
    /**
     * @notice Modifier is needed to control access
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}
