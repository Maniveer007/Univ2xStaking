// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import SafeERC20 library from OpenZeppelin to handle ERC20 transfers safely
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";// Import the ERC4626 vault for yield optimization
import "./interfaces/IUniswapV2Pair.sol"; // Interface for interacting with Uniswap V2 pair
import './libraries/TransferHelper.sol'; // Helper library for safe transfers
import './interfaces/IStakingContract.sol'; // Interface for the staking contract

// Main contract that interacts with Uniswap, Staking, and ERC4626 Vault
contract StrategyContract {
    using SafeERC20 for IERC20;

    // State variables to store references to important contracts
    IUniswapV2Pair public uniswapPair; // Uniswap pair contract for liquidity provision
    IStakingContract public stakingContract; // Staking contract interface
    IERC4626 public vault; // ERC4626 vault for managing deposits and rewards

    // Special slot for reentrancy protection (used in lock modifier)
    uint private unlocked ;

    // Modifier to prevent reentrancy attacks
    modifier lock() {
        require(unlocked == 1, 'Strategy Contract: LOCKED'); // Ensure the contract is unlocked
        unlocked = 0; // Lock the contract
        _; // Execute the rest of the function
        unlocked = 1; // Unlock the contract after function execution
    }

    /**
     * @notice Initializes the strategy contract by setting the key contract addresses.
     * @param _uniswapPair Address of the Uniswap pair for liquidity provision.
     * @param _stakingContract Address of the staking contract for staking LP tokens.
     * @param _vault Address of the ERC4626 vault for managing vault shares.
     */
    function initialize(
        address _uniswapPair,
        address _stakingContract,
        address _vault
    ) public {
        require(address(uniswapPair) == address(0) , "StrategyContract : Already initialized");
        unlocked = 1; // Ensure the contract is unlocked when initialized
        uniswapPair = IUniswapV2Pair(_uniswapPair); // Set the Uniswap pair contract
        stakingContract = IStakingContract(_stakingContract); // Set the staking contract
        vault = IERC4626(_vault); // Set the ERC4626 vault contract
    }

    /**
     * @notice Deposits tokens into Uniswap to add liquidity, stakes LP tokens in the staking contract, 
     * and mints vault shares for the user.
     * @param amountA The amount of token0 to add as liquidity.
     * @param amountB The amount of token1 to add as liquidity.
     */
    function deposit(uint256 amountA, uint256 amountB) external lock {
        // Get token addresses from the Uniswap pair
        address token0 = uniswapPair.token0();
        address token1 = uniswapPair.token1();

        // Transfer token0 and token1 from the user to the Uniswap pair contract
        IERC20(token0).transferFrom(msg.sender, address(uniswapPair), amountA);
        IERC20(token1).transferFrom(msg.sender, address(uniswapPair), amountB);

        // Mint liquidity tokens (LP tokens) and store the amount of liquidity provided
        uint liquidity = uniswapPair.mint(address(this));

        // Approve the staking contract to transfer the LP tokens
        IERC20 lpToken = IERC20(address(uniswapPair));
        lpToken.approve(address(stakingContract), liquidity);

        // Stake the LP tokens into the staking contract
        stakingContract.stake(liquidity);

        // Check the staking reward balance
        uint stakingReward = IERC20(address(stakingContract)).balanceOf(address(this));

        // Approve the vault to transfer the staking reward
        IERC20(address(stakingContract)).approve(address(vault), stakingReward);

        // Mint vault shares based on the staking reward and assign them to the user
        vault.deposit(stakingReward, msg.sender);
    }

    /**
     * @notice Withdraws tokens by redeeming vault shares, unstaking LP tokens, and removing liquidity from Uniswap.
     * @param shares The amount of vault shares to redeem.
     */
    function withdraw(uint256 shares) external lock {
        // Redeem vault shares for the equivalent amount of LP tokens
        uint256 amount = vault.redeem(shares, address(this), msg.sender);

        // Unstake LP tokens from the staking contract
        stakingContract.unstake(amount);

        // Get the balance of LP tokens held by the contract
        uint LPbalance = uniswapPair.balanceOf(address(this));

        // Transfer LP tokens to the Uniswap pair contract and burn them to retrieve the underlying tokens
        uniswapPair.transfer(address(uniswapPair), LPbalance); // Send LP tokens to pair
        uniswapPair.burn(msg.sender); // Burn LP tokens and return token0 and token1 to the user
    }

    /**
     * @notice Claims rewards by redeeming all vault shares and converting the rewards back into liquidity tokens.
     */
    function claimRewards() external {
        // Redeem all vault shares owned by the user
        uint stakingShares = vault.redeem(vault.balanceOf(msg.sender), address(this), msg.sender);

        // Unstake the equivalent amount of LP tokens from the staking contract
        stakingContract.unstake(stakingShares);

        // Get the balance of LP tokens held by the contract
        uint256 LPbalance = uniswapPair.balanceOf(address(this));

        // Transfer LP tokens to the Uniswap pair contract and burn them to return underlying tokens to the user
        uniswapPair.transfer(address(uniswapPair), LPbalance); // Send LP tokens to the pair
        uniswapPair.burn(msg.sender); // Burn LP tokens and return token0 and token1 to the user
    }

    /**
     * @notice Calculates the user's pending rewards in terms of token0 and token1.
     * @param user The address of the user to query rewards for.
     * @return token0 The amount of token0 rewards the user can claim.
     * @return token1 The amount of token1 rewards the user can claim.
     * @return LPbalance The amount of LP tokens the user has staked.
     */
    function getUserRewards(address user) external view returns (uint token0, uint token1, uint LPbalance) {
        // Get the user's vault shares and convert them to the equivalent staking rewards
        uint stakingShares = vault.convertToAssets(vault.balanceOf(user));
        LPbalance = stakingContract.getReward(stakingShares); // Get the LP token balance from staking contract

        // Get the current reserves of token0 and token1 from the Uniswap pair
        (uint reserve0, uint reserve1,) = uniswapPair.getReserves();

        // Calculate the user's share of token0 and token1 based on their LP token balance
        token0 = (LPbalance * reserve0) / uniswapPair.totalSupply();
        token1 = (LPbalance * reserve1) / uniswapPair.totalSupply();
    }
}
