pragma solidity ^0.4.25;

/**
 * @title Token History
 * @author Dominik Sturhan
 * 
 * @notice This contract records histor balances of a shareholder
 * 
 * @dev inspired from Jordi Baylina's MiniMeToken and Validity Lab's 
 *  Token Voting System to record historical balances
 */
contract TokenHistory {
    
    /**
     * @dev The 'Checkpoint' describes the structure in which the 'balance' 
     *  with the respective 'block' is stored
     */
    struct Checkpoint {
        // `block` is the block number that the balance was generated
        uint128 block;
        
        // `balance` is the amount of tokens at a specific block number
        uint128 balance;
    }   
    
    // Tracks the history of the total supply of the token
    Checkpoint[] internal totalSupplyHistory;
    
    // `balances` is the map that tracks every checkpoint of each address
    mapping (address => Checkpoint[]) internal balances;
    
    /// External functions ///
    
    /**
     * getBalance function
     * 
     * @notice Query the current balance of the sender
     * 
     * @return balance The amount of token owned by the sender
     */
    function getBalance() external view returns (uint balance) {
         return _getBalanceAt(balances[msg.sender], block.number);
    }
    
    /**
     * getBalanceAt function
     * 
     * @notice Query the historical balance of '_address' at '_block'
     * 
     * @param _address The address whose balance is queried
     * @param _block The block number when the balance is queried
     * @return balance The amount of token owned by the '_address' at '_block'
     */
    function getBalanceAt(
        address _address, 
        uint _block
    ) external view returns (uint balance) {
         return _getBalanceAt(balances[_address], _block);
    }

    /**
     * getTotalSupply function
     * 
     * @notice get the current total supply
     * 
     * @return totalSupply The total supply of the Forest Token
     */
    function getTotalSupply() external view returns (uint totalSupply) {
         return _getBalanceAt(totalSupplyHistory, block.number);
    }
    
    /**
     * getTotalSupplyAt function
     * 
     * @notice Query the historical total supply at '_block'
     * 
     * @param _block The block number when the total supply is queried
     * @return totalSupply The historical total supply of the Forest Token
     */
    function getTotalSupplyAt(
        uint _block
    ) external view returns (uint totalSupply) {
         return _getBalanceAt(totalSupplyHistory, _block);
    }
    
    /// Internal functions ///
    
     /**
     * _getBalanceAt function
     * 
     * @notice Obtains the amount of tokens at '_block'
     * 
     * @dev It is an internal function called by the external functions with 
     *  different '_checkpoints'
     * 
     * @param _checkpoints The storage of historical balances
     * @param _block The block number when the balance is queried
     * @return The amount of tokens
     */
    function _getBalanceAt(
        Checkpoint[] storage _checkpoints, 
        uint _block
    ) view internal returns (uint) {
        // Shortcut, if there is no balance
        if (_checkpoints.length == 0) return 0;
        
        // Shortcut for the actual value
        if (_block >= _checkpoints[_checkpoints.length-1].block)
            return _checkpoints[_checkpoints.length-1].balance;
            
        // Shortcut for the first value
        if (_block < _checkpoints[0].block) return 0;

        // Binary search of the balance in the array
        uint min = 0;
        uint max = _checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (_checkpoints[mid].block <= _block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return _checkpoints[min].balance;
    }

    /**
     * _updateBalanceAtNow function
     * 
     * @notice Updates the balance
     * 
     * @dev It is an internal function to update the balance of an address or 
     *  the total supply
     * 
     * @param _checkpoints The storage of historical balances
     * @param _balance The new balance which will be stored
     */
    function _updateBalanceAtNow(
        Checkpoint[] storage _checkpoints, 
        uint _balance
    ) internal {
        if ((_checkpoints.length == 0) 
         || (_checkpoints[_checkpoints.length -1].block < block.number)) {
            // Create a new checkpoint at the end of the array
            Checkpoint storage newCheckPoint = 
             _checkpoints[_checkpoints.length++];
            
            // Set the 'block' of the new checkpoint 
            newCheckPoint.block =  uint128(block.number);
            
            // Set the 'balance' of the new checkpoint
            newCheckPoint.balance = uint128(_balance);
        } else {
            // If there are no checkpoints or the current 'block' is 
            //  smaller than the latest entry
            Checkpoint storage oldCheckPoint = 
             _checkpoints[_checkpoints.length-1];
            
            // Update the old Checkpoint
            oldCheckPoint.balance = uint128(_balance);
       }
    }
}
