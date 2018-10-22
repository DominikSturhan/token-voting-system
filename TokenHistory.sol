pragma solidity ^0.4.25;

/**
 * @title This contract stores the history of a token
 * @author Dominik Sturhan
 */

contract TokenHistory {
    
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
    Checkpoint[] internal totalSupplyHistory;
    
    // `balances` is the map that tracks the balance of each address
    mapping (address => Checkpoint[]) internal balances;
    
    /// External functions ///
    
    /**
     * getBalance function
     * 
     * @notice get the current balance of sender
     * 
     * @return returns the amount owned by the sender
     */
    function getBalance() external view returns (uint amount) {
         return _getBalanceAt(balances[msg.sender], block.number);
    }
    
    /**
     * getBalanceAt function
     * 
     * @notice get the current balance of sender
     * 
     * @return returns the amount owned by the sender
     */
    function getBalanceAt(
        address addr, 
        uint _block
    ) external view returns (uint amount) {
         return _getBalanceAt(balances[addr], _block);
    }

    /**
     * getTotalSupplyAt function
     * 
     * @notice get the current balance of sender
     * 
     * @return returns the amount owned by the sender
     */
    function getTotalSupplyAt(
        uint _block
    ) external view returns (uint amount) {
         return _getBalanceAt(totalSupplyHistory, _block);
    }
    
    /**
     * getTotalSupply function
     * 
     * @notice get the current balance of sender
     * 
     * @return returns the amount owned by the sender
     */
    function getTotalSupply() external view returns (uint amount) {
         return _getBalanceAt(totalSupplyHistory, block.number);
    }
    
    /// Internal functions ///
    
     /**
     * _getBalanceAt function
     * 
     * @notice `_getBalanceAt` retrieves the number of tokens at a 
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
    ) view internal returns (uint) {
        
        // Shortcut, if there is no balance
        if (checkpoints.length == 0) return 0;
        
        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].amount;
            
        // Shortcut for the first value
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the balance in the array
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
    ) internal returns (bool success) {
        
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
