pragma solidity ^0.4.25;

contract Controller {
    
    // Public variables
    address public owner;

    /**
     * Constructor function
     * 
     * @notice Startup function to define that the contract creator is owner
     */
    constructor() public {
        owner = msg.sender;
    }
    
    /**
     * @notice Modifier is needed to control access
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * transferOwnership function
     * 
     * @notice Transfers ownership of ForestToken
     * @param  newOwner Adress of the new owner
     */
    function transferOwnership(
        address newOwner
    ) external onlyOwner {
        owner = newOwner;
    }
}
