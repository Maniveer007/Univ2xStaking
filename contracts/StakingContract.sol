// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import ERC20 and Ownable contracts from OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/IStakingContract.sol';

// StakingContract inherits the IStakingContract interface, Ownable for ownership control, and ERC20 for minting staking shares
contract StakingContract is IStakingContract, ERC20 {
    // The token that will be staked
    IERC20 public stakingToken;
    
    // Tracks the total number of tokens staked in the contract
    uint256 public totalStaked;

    // Constructor initializes the staking token and assigns ownership to the strategy contract
    constructor(address _stakingToken) 
        ERC20("Staking Share", "SHARE") // Token name is "Staking Share" and symbol is "SHARE"
    {
        stakingToken = IERC20(_stakingToken); // Assign the provided address as the staking token
    }
    
    /**
     * @notice Allows the owner to stake tokens into the contract in exchange for staking shares.
     * The number of shares minted is proportional to the amount of tokens staked.
     * @param _amount The amount of tokens to stake.
     */
    function stake(uint256 _amount) external updatetotalStaked {
        require(_amount > 0, "Amount must be greater than 0"); // Ensure the amount is greater than zero
        
        // Transfer the staking tokens from the owner (msg.sender) to this contract
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        
        uint256 sharesToMint; // The amount of shares to mint based on the staking amount

        // If this is the first stake (no totalStaked), mint 1:1 shares based on the staked amount
        if (totalStaked == 0) {
            sharesToMint = _amount;
        } else {
            // Calculate shares based on the proportion of staked tokens to total tokens in the contract
            sharesToMint = (_amount * totalSupply()) / totalStaked;
        }
        
        // Mint the calculated amount of shares to the owner (msg.sender)
        _mint(msg.sender, sharesToMint);
        
        // Increase the total amount of staked tokens
        totalStaked += _amount;
    }
    
    /**
     * @notice Allows the owner to unstake tokens by burning staking shares.
     * The amount of tokens returned is proportional to the number of shares burned.
     * @param _shareAmount The amount of staking shares to burn.
     */
    function unstake(uint256 _shareAmount) external updatetotalStaked {
        require(balanceOf(msg.sender) >= _shareAmount, "Not enough shares"); // Ensure the user has enough shares to burn

        // Calculate the equivalent amount of staked tokens to return based on the burned shares
        uint256 stakedAmount = (_shareAmount * totalStaked) / totalSupply();
        
        // Burn the shares from the owner's (msg.sender) balance
        _burn(msg.sender, _shareAmount);
        
        // Transfer the calculated amount of staking tokens back to the owner (msg.sender)
        stakingToken.transfer(msg.sender, stakedAmount);
        
        // Reduce the total staked amount by the equivalent staked tokens
        totalStaked -= stakedAmount;
    }

    /**
     * @notice Calculates the reward (or amount of staked tokens) equivalent to a given number of staking shares.
     * This does not transfer any tokens but allows the user to see how much they can redeem.
     * @param _shareAmount The number of shares to calculate the reward for.
     * @return rewardAmount The amount of staked tokens equivalent to the given shares.
     */
    function getReward(uint256 _shareAmount) external view returns (uint256) {
        require(_shareAmount > 0, "Share amount must be greater than 0"); // Ensure the share amount is greater than zero
        require(totalSupply() > 0, "No shares have been minted"); // Ensure shares exist
        
        // Get the total number of staked tokens in the contract at the moment
        uint _totalStaked = stakingToken.balanceOf(address(this));

        // Calculate the reward amount based on the share amount and the total staked tokens
        uint256 rewardAmount = (_shareAmount * _totalStaked) / totalSupply();
        return rewardAmount;
    }

    /**
     * @notice Updates the total staked amount in the contract to match the actual balance of staking tokens.
     * This modifier is used in the stake and unstake functions to keep totalStaked accurate.
     */
    modifier updatetotalStaked() {
        // to update if contract receives tokens from other sources
        totalStaked = stakingToken.balanceOf(address(this)); // Update totalStaked to the current balance of staking tokens
        _; // Continue with the execution of the function
    }
}
