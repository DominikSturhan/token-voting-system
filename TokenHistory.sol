pragma solidity ^0.4.25;

/**
 * @title This contract stores the history of a token
 * @author Dominik Sturhan
 */
 
/**
 * @dev Only the owner, the token contract and the voting contract are 
 *  allowed to access.
 */
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
    constructor(
        address _token,
        address _voting
    ) public {
        owner = msg.sender;
        token = _token;
        voting = _voting;
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

contract TokenHistory is controlled {
    
    /**
     * @dev `Checkpoint` is the structure that attaches a block number to a
     *  given amount, the block number attached is the one that last changed the
     *  amount
     */
    struct Checkpoint {
        // `fromBlock` is the block number that the value was generated
        uint128 fromBlock;
        
        // `amount` is the amount of tokens at a specific block number
        uint128 amount;
    }   
    
    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;
    
    // `balances` is the map that tracks the balance of each address
    mapping (address => Checkpoint[]) balances;

    /// External functions ///    
    
    /**
     * getBalanceAt function
     * 
     * @notice `getBalanceAt` retrieves the number of tokens at a 
     *  given block number
     * @dev It is the external function, only accessable 
     *  from the voting contract
     * @param _owner Address whose history of balances being queried
     * @param _block The block number to retrieve the amount at
     * @return The number of tokens being queried
     */
    function getBalanceAt(
        address _owner,
        uint _block
    ) constant external onlyController returns (uint) {
        return _getBalanceAt(balances[_owner], _block);
    }
    
    /**
     * getTotalSupplyAt function
     * 
     * @notice `getTotalSupplyAt` retrieves the number of tokens at a 
     *  given block number
     * @dev It is the external function, only accessable 
     *  from the voting contract
     * @param _block The block number to retrieve the amount at
     * @return The number of tokens being queried
     */
    function getTotalSupplyAt(
        uint _block
    ) constant external onlyController returns (uint) {
        return _getBalanceAt(totalSupplyHistory, _block);
    }
    
    /**
     * updateBalanceAtNow function
     * 
     * @notice This function creates a new entry in the history
     * @dev It is the external function, only accessable 
     *  from the voting contract
     * @param _owner Address whose history of data being updated
     * @param _amount The new number of tokens
     */
    function updateBalanceAtNow(
        address _owner,
        uint _amount
    ) external onlyController returns (bool success) {
        return _updateBalanceAtNow(balances[_owner], _amount);
    }
    
    /**
     * updateTotalSupplyAtNow function
     * 
     * @notice This function creates a new entry in the history
     * @dev It is the external function, only accessable 
     *  from the voting contract
     * @param _amount The new number of tokens
     */
    function updateTotalSupplyAtNow(
        uint _amount
    ) external onlyController returns (bool success) {
        return _updateBalanceAtNow(totalSupplyHistory, _amount);
    }
    
    /// Internal functions ///
    
     /**
     * _getBalanceAt function
     * 
     * @notice `getBalanceAt` retrieves the number of tokens at a 
     *  given block number
     * @dev It is an internal function, the query function use it to get the
     *  the number of tokens
     * @param checkpoints The history of balances being queried
     * @param _block The block number to retrieve the value at
     * @return The number of tokens being queried
     */
    function _getBalanceAt(
        Checkpoint[] storage checkpoints, 
        uint _block
    ) constant internal returns (uint) {
        // Shortcut, if there is no balance
        if (checkpoints.length == 0) return 0;
        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].amount;
        // Shortcut for the first value
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].amount;
    }

    /**
     * _updateBalanceAtNow function
     * 
     * @notice This function creates a new entry in the history
     * @dev `updateBalanceAtNow` used to update the `balances` map and the
     *  `totalSupplyHistory`
     * @param checkpoints The history of data being updated
     * @param _amount The new number of tokens
     */
    function _updateBalanceAtNow(
        Checkpoint[] storage checkpoints, 
        uint _amount
    ) internal  returns (bool success) {
        if ((checkpoints.length == 0) 
         || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
            // New checkpoint at the end of the array
            Checkpoint storage newCheckPoint = 
             checkpoints[checkpoints.length++];
            
            // Set the block.number of the new checkpoint 
            newCheckPoint.fromBlock =  uint128(block.number);
            
            // Set the value of the new checkpoint
            newCheckPoint.amount = uint128(_amount);
        } else {
            // If there are no checkpoints or the current block.number is 
            //  smaller than the latest entry
            Checkpoint storage oldCheckPoint = 
             checkpoints[checkpoints.length-1];
            
            // Update the old Checkpoint
            oldCheckPoint.amount = uint128(_amount);
       }
       
       return true;
    }
}
