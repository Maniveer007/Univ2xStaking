// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IStakingContract  {
    
    // Returns the total amount of tokens staked
    function totalStaked() external view returns (uint256);
    
    // Stake a specified amount of tokens
    function stake(uint256 _amount) external;
    
    // Unstake a specified amount of shares and return the equivalent amount of tokens
    function unstake(uint256 _shareAmount) external;
    
    // Calculate the reward for a given amount of shares
    function getReward(uint256 _shareAmount) external view returns (uint256);


}
