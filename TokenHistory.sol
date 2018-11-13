pragma solidity ^0.4.25;
import './Controller.sol';

/**
 * @title TokenHistory
 * @author Dominik Sturhan
 * 
 * @notice This contract records historical balances of a shareholder
 * 
 * @dev This contract is accessible only through the Token contract. 
 *  All functions are restricted.
 */
contract TokenHistory is Controller {
    
    /// Structs ///
    
    /**
     * @dev The 'Checkpoint' describes the structure in which the 'balance' 
     *  with the respective 'block' is stored
     */
    struct Checkpoint {
        // `block` is the block number that the balance was generated
        uint block;
        
        // `balance` is the number of tokens at a specific block number
        uint balance;
    }  
    
    /// Variables ///
    
    // Tracks the history of the total supply of the token
    Checkpoint[] internal totalSupplyHistory;
    
    // `balances` is the map that tracks every Checkpoint of each address
    mapping (address => Checkpoint[]) internal balances;
    
    address public token;
    
    /// Modifiers ///
    
    modifier onlyToken {
        require(msg.sender == token);
        _;
    }
    
    /// Functions ///
    
    /**
     * changeToken function
     * 
     * @notice Set or change the token
     * 
     * @dev This function has restricted access. Only the owner is allowed 
     *  to change the token
     * 
     * @param _token Address of the Token contract
     */
    function changeToken(
        address _token
    ) external onlyOwner {
        token = _token;
    }
    
    /**
     * getBalanceAt function
     * 
     * @notice Query the historical balance of '_address' at '_block'
     * 
     * @param _address The address whose balance is queried
     * @param _block The block number when the balance is queried
     * @return The number of token owned by the '_address' at '_block'
     */
    function getBalanceAt(
        address _address, 
        uint _block
    ) external view onlyToken returns (uint) {
         return _getBalanceAt(balances[_address], _block);
    }

    /**
     * getTotalSupplyAt function
     * 
     * @notice Query the historical total supply at '_block'
     * 
     * @param _block The block number when the total supply is queried
     * @return The historical total supply
     */
    function getTotalSupplyAt(
        uint _block
    ) external view onlyToken returns (uint) {
         return _getBalanceAt(totalSupplyHistory, _block);
    }
    
    /**
     * updateBalanceNow function
     * 
     * @notice The balance of the shareholder will be updated
     * 
     * @param _shareholder Address of the shareholder
     * @param _balance The new balances
     */
    function updateBalanceNow(
        address _shareholder,
        uint _balance
    ) external onlyToken {
        _updateBalanceNow(balances[_shareholder], _balance);
    }
    
    /**
     * updateTotalSupplyNow function
     * 
     * @notice The total supply will be updated
     * 
     * @param _totalSupply The new total supply
     */
    function updateTotalSupplyNow(
        uint _totalSupply
    ) external onlyToken {
        _updateBalanceNow(totalSupplyHistory, _totalSupply);
    }
    
    /**
     * _getBalanceAt function
     * 
     * @notice Obtains the number of tokens at '_block'
     * 
     * @dev It is an internal function called by the external functions with 
     *  different '_checkpoints'
     * 
     * @param _checkpoints The storage of historical balances
     * @param _block The block number when the balance is queried
     * @return The number of tokens
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
     * _updateBalanceNow function
     * 
     * @notice Updates the balance
     * 
     * @dev It is an internal function to update the balance of an address or 
     *  the total supply
     * 
     * @param _checkpoints The storage of historical balances
     * @param _balance The new balance which will be stored
     */
    function _updateBalanceNow(
        Checkpoint[] storage _checkpoints, 
        uint _balance
    ) internal {
        if ((_checkpoints.length == 0) 
         || (_checkpoints[_checkpoints.length -1].block < block.number)) {
            // Create a new checkpoint at the end of the array
            Checkpoint storage newCheckPoint = 
             _checkpoints[_checkpoints.length++];
            
            // Set the 'block' of the new checkpoint 
            newCheckPoint.block =  uint256(block.number);
            
            // Set the 'balance' of the new checkpoint
            newCheckPoint.balance = uint256(_balance);
        } else {
            // If there are no checkpoints or the current 'block' is 
            //  smaller than the latest entry
            Checkpoint storage oldCheckPoint = 
             _checkpoints[_checkpoints.length-1];
            
            // Update the old Checkpoint
            oldCheckPoint.balance = uint256(_balance);
       }
    }
}
