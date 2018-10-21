pragma solidity ^0.4.25;

contract controlled {
    
    // Public variables
    address public owner;
    address public token;
    address public voting;
    
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
    modifier onlyController {
        require(msg.sender == owner || msg.sender == token 
         || msg.sender == voting);
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
    ) external onlyController {
        owner = newOwner;
    }
    
    /**
     * changeToken function
     * 
     * @notice Changes the address of token contract
     * @param newToken Adress of new token contract
     */
    function changeToken(
        address newToken
    ) external onlyController {
        token = newToken;
    }
    
    /**
     * changeVoting function
     * 
     * @notice Changes the address of voting contract
     * @param newVoting Adress of new voting contract
     */
    function changeVoting(
        address newVoting
    ) external onlyController {
        voting = newVoting;
    }
}
