pragma solidity ^0.4.25;
import './TokenHistory.sol';
import './Controller.sol';

/**
 * @title Forest Token
 * @author Dominik Sturhan
 * 
 * @notice This contract is the token contract. 
 * 
 * @dev It inherits from the contracts TokenHistory and Controller. If 
 *  TokenHistory were a stand-alone contract, it would result in unnecessary 
 *  transactions between this contract and the TokenHistory contract.
 */
contract ForestToken is TokenHistory, Controller {
    
    // Public variables
    string public tokenName;
    string public tokenSymbol;

    // This generates public events on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    
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
     * transfer function
     * 
     * @notice send '_amount' tokens to '_to' from the sender's account
     * 
     * @param _to The address of the recipient
     * @param _amount The amount of token to send
     * @return True if succesful
     */
    function transfer(
        address _to, 
        uint256 _amount
    ) public returns (bool success) {
        // Get checkpoints of 'sender' and '_to'
        Checkpoint[] storage checkpointsFrom = balances[msg.sender];
        Checkpoint[] storage checkpointsTo = balances[_to]; 
        
        // Get the current balance of each
        uint balanceFrom = _getBalanceAt(checkpointsFrom, block.number);
        uint balanceTo = _getBalanceAt(checkpointsTo, block.number);
        
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceFrom >= _amount);
        // Check for overflows
        require(balanceFrom + _amount >= balanceTo);

        // Subtract from the sender
        _updateBalanceAtNow(checkpointsFrom, balanceFrom - _amount);
        // Add the same to the recipient
        _updateBalanceAtNow(checkpointsTo, balanceTo + _amount);
        
        // Fire event
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    /**
     * mintToken function
     * 
     * @notice Create new token and transfer them to target
     * 
     * @param _target The address of the recipient
     * @param _mintedAmount The amount of token to mint
     * @return True if succesful
     */
    function mintToken(
        address _target, 
        uint256 _mintedAmount
    ) public onlyOwner returns (bool success) {
        // Get checkpoints of '_target'
        Checkpoint[] storage checkpointsTo = balances[_target];
        
        uint balancesTarget = _getBalanceAt(checkpointsTo, block.number);
        uint totalSupply = _getBalanceAt(totalSupplyHistory, block.number);
        
        _updateBalanceAtNow(checkpointsTo, balancesTarget + _mintedAmount);
        _updateBalanceAtNow(totalSupplyHistory, totalSupply + _mintedAmount);

        // Fire event
        emit Mint(_target, _mintedAmount);
        
        return true;
    }
    
    /**
     * burn function
     *
     * @notice Remove `_amount` tokens from the system irreversibly
     *
     * @param _target The address of the recipient
     * @param _burnedAmount The amount of token to burn
     * @return True if succesful
     */
    function burn(
        address _target, 
        uint256 _burnedAmount
    ) public onlyOwner returns (bool success) {
        Checkpoint[] storage checkpointsTo = balances[_target];
        
        uint balancesTarget = _getBalanceAt(checkpointsTo, block.number);
        uint totalSupply = _getBalanceAt(totalSupplyHistory, block.number);
        
        require(balancesTarget >= _burnedAmount);
        _updateBalanceAtNow(checkpointsTo, balancesTarget - _burnedAmount);
        _updateBalanceAtNow(totalSupplyHistory, totalSupply - _burnedAmount);

        emit Burn(_target, _burnedAmount);
        return true;
    }
}
