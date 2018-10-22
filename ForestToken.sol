pragma solidity ^0.4.25;
import './TokenHistory.sol';
import './Controller.sol';


contract ForestToken is TokenHistory, Controller {
    
    // Public variables
    string public tokenName;
    string public tokenSymbol;
    uint8 public decimals = 18;

    // This generates public events on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    
    /**
     * constructor function
     * 
     * Initializes contract with the initial supply tokens to the creator of 
     *  the contract
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
     * @notice send '_amount' tokens to '_to' from your account
     * 
     * @param _to The address of the recipient
     * @param _amount the amount to send
     */
    function transfer(
        address _to, 
        uint256 _amount
    ) public returns (bool success) {
        // Get checkpoints of sender and recipient
        Checkpoint[] storage checkpointsFrom = balances[msg.sender];
        Checkpoint[] storage checkpointsTo = balances[_to]; 
        
        // Get the current balance
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
        
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    /**
     * mintToken function
     * 
     * @notice creates new token and transfers them to target
     * 
     * @param _target The address of the recipient
     * @param _mintedAmount the amount to mint
     */
    function mintToken(
        address _target, 
        uint256 _mintedAmount
    ) public onlyOwner returns (bool success) {
        Checkpoint[] storage checkpointsTo = balances[_target];
        
        uint balancesTarget = _getBalanceAt(checkpointsTo, block.number);
        uint totalSupply = _getBalanceAt(totalSupplyHistory, block.number);
        
        _updateBalanceAtNow(checkpointsTo, balancesTarget + _mintedAmount);
        _updateBalanceAtNow(totalSupplyHistory, totalSupply + _mintedAmount);

        emit Mint(_target, _mintedAmount);
        
        return true;
    }
    
    /**
     * burn function
     *
     * @notice Remove `_amount` tokens from the system irreversibly
     *
     * @param _burnedAmount the amount of money to burn
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
