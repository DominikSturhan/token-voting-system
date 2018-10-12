pragma solidity ^0.4.18;

/**
 * @title This is the token contract for a token voting system
 * @author Dominik Sturhan
 */
 
/**
 * @dev The access to the functions of the ForestToken needs to be controlled
 */
contract accessControlled {
    
    // Public varables
    address public owner;
    address public votingContract;
    
    /**
     * Constructor function
     * 
     * @notice Startup function to define that the contract creator is owner
     */
    function accessControlled() {
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
     * @notice Modifier is needed to control access
     */
    modifier onlyVotingContract {
        require(msg.sender == votingContract);
        _;
    }
    
    /**
     * transferOwnership function
     * 
     * @notice Transfers ownership of ForestToken
     * @param  newOwner Adress of the new owner
     */
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    
    /**
     * changeVotingContract function
     * 
     * @notice Changes adress of voting contract
     * @param newVotingContract Adress of new voting contract
     */
    function changeVotingContract(address newVotingContract) onlyOwner {
        votingContract = newVotingContract;
    }
}

/**
 * @dev Inspired from Jordi Baylina's MiniMeToken and Roland Kofler's
 *  LoggedToken to record historical balances
 */
contract ForestToken is accessControlled{
    
    // Public variables of the token
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;
    
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


    // `balances` is the map that tracks the balance of each address, in this
    //   contract when the balance changes the block number that the change
    //   occurred is also included in the map
    mapping (address => Checkpoint[]) balances;
    
    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;
    
    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;                                            
   
   // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Burn(address indexed _from, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, 
     uint256 _amount);
        
    /**
     * Constructor function
     *
     * @notice Initializes contract with initial supply tokens to the 
     *  creator of the contract
     */
    function ForestToken(
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        updateValueAtNow(totalSupplyHistory,0);                     
    }

    /**
     * mintToken function
     * 
     * @notice Enables the owner to create '_amount' tokens and send it to '_to'
     * @param _to Recipient of the minted tokens
     * @param _amount Amount of the minted tokens
     */
    function mintToken(
        address _to, 
        uint256 _amount
    ) onlyOwner {
        // Get the current total supply
        uint curTotalSupply = totalSupply;
        // Get the currect balance of the recipient
        uint previousBalanceTo = balanceOf(_to);
        
        // Check for overflow 
        require(curTotalSupply + _amount >= curTotalSupply);
        // Check for overflow
        require(previousBalanceTo + _amount >= previousBalanceTo);
        
        // Update the histories of the total supply and the recipient
        updateValueAtNow(totalSupplyHistory, curTotalSupply+ _amount);
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);
        
        // Emit event
        Transfer(0, _to, _amount);
    }


    /**
     * transfer function
     * 
     * @notice Send `_amount` tokens to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(
        address _to, 
        uint256 _amount
    ) public returns (bool success) {
        return _transfer(msg.sender, _to, _amount);
    }

    /**
     * transferFrom function - not finished, require missing
     * 
     * @notice Send `_amount` tokens to `_to` from `_from` on the condition it
     *  is approved by `_from`
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return True if the transfer was successful
     */
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _amount
    ) public returns (bool success) {
        return _transfer(_from, _to, _amount);
    }

    /**
     * _transfer function
     * 
     * @dev This is the actual transfer function in the token contract, it can
     *  only be called by other functions in this contract
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return True if the transfer was successful
     */
    function _transfer(
        address _from, 
        address _to, 
        uint _amount
    ) internal returns(bool) {
        // Check if the amount is not zero
        if (_amount == 0) {
            return true;
        }

        // Do not allow transfer to 0x0. Use burn() instead 
        require(_to != 0x0);
        // Do not allow transfer to the token contract itself
        require(_to != address(this));
        // Check if the sender has enough
        require(balanceOf(_from) >= _amount);
        // Check for overflow
        require(balanceOf(_to) + _amount > balanceOf(_to));
        
        // Save this for an assertion in the future
        uint previousBalance = balanceOf(_from) + balanceOf(_to);
        
        // Subtract from the sender
        updateValueAtNow(balances[_from], balanceOf(_from) - _amount);
        // Add to the recipient
        updateValueAtNow(balances[_to], balanceOf(_to) + _amount);
        
        // Emit event
        Transfer(_from, _to, _amount);
        
        // Asserts are used to use static analysis to find bugs in the code
        assert(balanceOf(_from) + balanceOf(_to) == previousBalance);
        
        return true;
    }

    /**
     * balanceOf function
     * 
     * @notice Get the current balance of an address
     * @param _owner The address that's balance is being requested
     * @return The balance of `_owner` at the current block
     */
    function balanceOf(
        address _owner
    ) public constant returns (uint256 balance) {
        return getValueAt(balances[_owner], block.number);
    }
    
    /**
     * balanceOfAt function
     * 
     * @notice Queries the balance of `_owner` at a specific `_block`
     * @dev The function can only be accessed by the voting contract. No one 
     *  else is allowed to view in the history
     * @param _owner The address from which the balance will be retrieved
     * @param _block The block number when the balance is queried
     * @return The balance at `_block`
     */
    function balanceOfAt(
        address _owner, 
        uint _block
    ) public constant onlyVotingContract returns (uint) {
        return getValueAt(balances[_owner], _block);
    }
    
    /**
     * totalSupply function
     * 
     * @notice Total amount of tokens
     * @return The total amount of tokens at `_blockNumber`
     */
    function totalSupply() public constant returns(uint) {
        return getValueAt(totalSupplyHistory, block.number);
    }
    
    /**
     * totalSupplyAt function
     * 
     * @notice Total amount of tokens at a specific `_block`
     * @param _block The block number when the totalSupply is queried
     * @return The total amount of tokens at `_block`
     */
    function totalSupplyAt(
        uint _block
    ) public constant onlyVotingContract returns(uint) {
        return getValueAt(totalSupplyHistory, _block);
    }
    
    /**
     * GetValueAt function
     * 
     * @notice `getValueAt` retrieves the number of tokens at a 
     *  given block number
     * @dev It is an internal function, the query function use it to get the
     *  the number of tokens
     * @param checkpoints The history of values being queried
     * @param _block The block number to retrieve the value at
     * @return The number of tokens being queried
     */
    function getValueAt(
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
     * updateValueAtNow function
     * 
     * @notice This function creates a new entry in the history
     * @dev `updateValueAtNow` used to update the `balances` map and the
     *  `totalSupplyHistory`
     * @param checkpoints The history of data being updated
     * @param _amount The new number of tokens
     */
    function updateValueAtNow(
        Checkpoint[] storage checkpoints, 
        uint _amount
    ) internal  {
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
    }
    
    /**
    * approve function
    * 
    * @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    *  its behalf. This is a modified version of the ERC20 approve function
    *  to be a little bit safer
    * @param _spender The address of the account able to transfer the tokens
    * @param _amount The amount of tokens to be approved for transfer
    * @return True if the approval was successful
    */
    function approve(
        address _spender, 
        uint256 _amount
    ) public returns (bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        // Set the amount of tokens to be approved for transfer
        allowed[msg.sender][_spender] = _amount;
        
        // Emit event
        Approval(msg.sender, _spender, _amount);
        
        return true;
    }

    /**
     * allowance function
     * 
     * @dev This function makes it easy to read the `allowed[]` map
     * @param _owner The address of the account that owns the token
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens of _owner that _spender is allowed
     *  to spend
     */
    function allowance(
        address _owner, 
        address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * burn function
     * 
     * @notice Remove '_amount' tokens from the system irreversibly
     * @dev Only the owner is allowed to burn token
     * @param _amount the amount of tokens to burn
     * @return True if the burn was successful
     */
    function burn(
        uint256 _amount
    ) public onlyOwner returns (bool success) {
        // Check if the balance is enough
        require(balanceOf(msg.sender) >= _amount);
        // Update the balanceOf
        updateValueAtNow(balances[msg.sender], balanceOf(msg.sender) - _amount);
        // Update the total supply
        updateValueAtNow(totalSupplyHistory, totalSupply() - _amount);
        
        // Emit event
        Burn(msg.sender, _amount);
        
        return true;
        
    }
    
    /**
     * burnFrom function
     * 
     * @notice Remove '_amount' tokens from the system irreversibly on behalf 
     *  of '_from'
     * @dev Only the owner is allowed to burn token on behalf of '_from', if
     *  '_from' allowed him to
     * @param _from the address of the sender
     * @param _amount the amount of token to burn
     * @return True if the burn was successful
     */
    function burnFrom(
        address _from,
        uint256 _amount
    ) public onlyOwner returns (bool success) {
        // Check if the owner is allowed
        require(allowed[msg.sender][_from] >= _amount);
        // Check if the balance is enough
        require(balanceOf(_from) >= _amount);
        // Update the balanceOf
        updateValueAtNow(balances[_from], balanceOf(_from) - _amount);
        // Update the total supply
        updateValueAtNow(balances[totalSupplyHistory], totalSupply() - _amount);
        // Update the amount of token allowed to Burn
        allowed[msg.sender][_from] -= _amount;
        
        // Emit event
        Burn(_from , _amount);
        
        return true;
    }
}
