# Advanced ERC4626 Vault Project with Uniswap V2 Integration

## Project Overview

The goal of this project is to develop an advanced ERC4626-compliant vault that integrates seamlessly with Uniswap V2, implements a custom staking mechanism, and leverages the ERC4626 standard to track user contributions while efficiently distributing rewards. This system is designed to optimize yield while maintaining compatibility with existing protocols like Uniswap, making it adaptable to real-world scenarios.

## Architecture

The architecture is composed of the following key components:

- **ERC4626 Vault**: Tracks user deposits and manages their shares within the vault.
- **Uniswap V2 Pair**: Facilitates liquidity provision for two specified tokens, allowing users to contribute liquidity and receive LP (Liquidity Provider) tokens in return.
- **Staking Contract**: Manages the staking of LP tokens and distributes rewards based on users’ stakes.
- **Strategy Contract**: Acts as the central orchestrator, interacting with the vault, Uniswap, and the staking contract to ensure smooth operations.

### Important Note

Individual components in this system do not contain specific checks for only allowing interaction from the strategy contract. In real-world scenarios, protocols like Uniswap are used as existing, trusted contracts rather than creating protocol-specific versions of these components. This setup provides flexibility in integrating with existing DeFi infrastructure.

## Individual Contract Details

### Uniswap V2 Pair

This is an implementation of the Uniswap V2 pair contract, responsible for managing liquidity addition and removal. When users add liquidity to the system, they receive LP tokens in return.

**Reference**: [Uniswap V2 Pair Contract](https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol)

### Staking Contract

The staking contract allows users to stake their tokens. Based on the percentage of tokens contributed to the contract, users receive a corresponding amount of staking shares.

**Staking Share Token**: This receipt token represents ownership of staked assets. If a user transfers their Staking Share tokens, they lose ownership of the staked assets.

#### Stake Functionality

- If the total staked tokens are 1000 and a user adds 100 tokens (10% of the total), the user will receive 10% of the total shares. For example, if there are 100 total shares, the user will receive 10 new shares.

#### Unstake Functionality

- If a user unstakes 30 shares from a total of 100 shares, representing 30% of the total, the contract will burn those shares and return 30% of the staked tokens (i.e., 300 tokens in this example).

Additionally, if the staking contract receives tokens from other sources, it distributes them proportionally to the users based on their shares.

### ERC4626 Vault

OpenZeppelin’s ERC4626 implementation is used for this vault. The vault holds users' staking reward tokens and mints vault tokens in return. Users have full control of their tokens within the vault and can burn their vault tokens to redeem their staking rewards.

## Main Functions in the Strategy Contract

### `deposit(uint256 amount0, uint256 amount1)`

- The user deposits tokens, which are then added as liquidity in the Uniswap V2 pair.
- The resulting LP tokens are staked in the staking contract.
- Staking reward tokens are stored in the ERC4626 vault, and the user is issued vault tokens in return.

### `withdraw(uint256 shares)`

- Burns the user’s shares in the ERC4626 vault.
- Unstakes the proportional amount of LP tokens from the staking contract.
- Removes liquidity from Uniswap V2.
- Returns the underlying assets (tokens) to the user.

### `getUserRewards(address user)`

- Retrieves the user’s staking rewards in the vault.
- Calculates and returns the proportional amounts of `token0` and `token1` that the user can receive if they were to withdraw their staking rewards.

### `claimRewards()`

- Allows the user to claim their entire balance of vault shares and withdraw all their rewards.

### `reinvestRewards()`

**Important**: This project implements an automatic reward compounding mechanism. Users do not need to call a separate function to claim or reinvest their rewards. The system is designed so that as a user’s stake grows, their rewards are automatically compounded. When the user unstakes their assets, they will receive the increased rewards without needing to manually reinvest.

## Deployment

To deploy the strategy module to the **Sepolia** network, use the following command:

```bash
npx hardhat ignition deploy ./ignition/modules/Strategy.js --network sepolia
```

## Testing

```bash
npx hardhat test

```
