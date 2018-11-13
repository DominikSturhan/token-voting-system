pragma solidity ^0.4.25;
import './TokenHistory.sol';
import './Controller.sol';

/**
 * @title Token
 * @author Dominik Sturhan
 * 
 * @notice This contract is the Token contract. 
 * 
 * @dev It inherits from the  Controller contract to control the access. 
 *  Each function in this contract results in an interaction with the 
 *  TokenHistory contract.
 */
contract Token is Controller {
    
    /// Variables ///
    
    // Public variables
    string public tokenName;
    string public tokenSymbol;

    /// Events ///

    // This generates public events on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    
    /// References ///
    
    // Reference to the token history
    TokenHistory history;
    
    /// Functions ///
    
    /**
     * Constructor function
     * 
     * @notice Initializes contract with the name and the symbol.
     */
    constructor(
        string _tokenName,
        string _tokenSymbol
    ) public {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
    }
    
    /**
     * setHistory function
     * 
     * @notice Set or change the token history
     * 
     * @dev This function has restricted access. Only the owner is allowed 
     *  to change the token history
     * 
     * @param _history Address of the token history contract
     */
    function changeHistory(
        address _history
    ) external onlyOwner{
        history = TokenHistory(_history);
    }
    
    /**
     * mintToken function
     * 
     * @notice Create new token and transfer them to target
     * 
     * @param _target The address of the recipient
     * @param _mintedAmount The number of token to mint
     */
    function mintToken(
        address _target, 
        uint256 _mintedAmount
    ) public onlyOwner {
        // Get the balance and the total supply
        uint balancesTarget = history.getBalanceAt(_target, block.number);
        uint totalSupply = history.getTotalSupplyAt(block.number);
        
        // Update the balance and the total supply
        history.updateBalanceNow(_target, balancesTarget + _mintedAmount);
        history.updateTotalSupplyNow(totalSupply + _mintedAmount);

        // Fire event
        emit Mint(_target, _mintedAmount);
    }
    
    /**
     * burnToken function
     *
     * @notice Remove `_amount` tokens from the system irreversibly
     *
     * @param _target The address of the recipient
     * @param _burnedAmount The number of token to burn
     */
    function burnToken(
        address _target, 
        uint256 _burnedAmount
    ) public onlyOwner {
        // Get the balance and the total supply
        uint balancesTarget = history.getBalanceAt(_target, block.number);
        uint totalSupply = history.getTotalSupplyAt(block.number);
        
        // Check if the balance is enough
        require(balancesTarget >= _burnedAmount);
        
        // Update the balance and the total supply
        history.updateBalanceNow(_target, balancesTarget - _burnedAmount);
        history.updateTotalSupplyNow(totalSupply - _burnedAmount);

        // Fire event
        emit Burn(_target, _burnedAmount);
    }
    
    /**
     * transfer function
     * 
     * @notice send '_amount' tokens to '_to' from the sender's account
     * 
     * @param _to The address of the recipient
     * @param _amount The number of token to send
     */
    function transfer(
        address _to, 
        uint256 _amount
    ) external {
        // Get the current balance of each
        uint balanceFrom = history.getBalanceAt(msg.sender, block.number);
        uint balanceTo = history.getBalanceAt(_to, block.number);
        
        // Prevent transfer to 0x0 address. Use burnToken() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceFrom >= _amount);
        // Check for overflows
        require(balanceFrom + _amount >= balanceTo);

        // Subtract from the sender
        history.updateBalanceNow(msg.sender, balanceFrom - _amount);
        // Add the same to the recipient
        history.updateBalanceNow(_to, balanceTo + _amount);
        
        // Fire event
        emit Transfer(msg.sender, _to, _amount);
    }
    
    /**
     * getBalance function
     * 
     * @notice Query the current balance of the sender
     * 
     * @return balance The number of token owned by the sender
     */
    function getBalance() external view returns (uint balance) {
         return history.getBalanceAt(msg.sender, block.number);
    }
    
    /**
     * getBalanceAt function
     * 
     * @notice Query the historical balance of '_address' at '_block'
     * 
     * @param _address The address whose balance is queried
     * @param _block The block number when the balance is queried
     * @return balance The number of token owned by the '_address' at '_block'
     */
    function getBalanceAt(
        address _address, 
        uint _block
    ) external view returns (uint balance) {
         return history.getBalanceAt(_address, _block);
    }

    /**
     * getTotalSupply function
     * 
     * @notice get the current total supply
     * 
     * @return totalSupply The total supply
     */
    function getTotalSupply() external view returns (uint totalSupply) {
         return history.getTotalSupplyAt(block.number);
    }
    
    /**
     * getTotalSupplyAt function
     * 
     * @notice Query the historical total supply at '_block'
     * 
     * @param _block The block number when the total supply is queried
     * @return totalSupply The historical total supply
     */
    function getTotalSupplyAt(
        uint _block
    ) external view returns (uint totalSupply) {
         return history.getTotalSupplyAt(_block);
    }
}
