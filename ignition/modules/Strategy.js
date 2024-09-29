const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("StrategyDeploymentModule", (m) => {
  // Parameters (these can be overridden when running the deployment)
  const owner = m.getAccount(0);

  // Deploy Token0 (MyToken)
  const token0 = m.contract("MyToken", [owner], { id: "id0" });

  // Deploy Token1 (MyToken)
  const token1 = m.contract("MyToken", [owner], { id: "id1" });

  // Deploy Uniswap V2 Pair (using token0 and token1 addresses)
  const uniswapv2pair = m.contract(
    "UniswapV2Pair",
    [
      token0, // Token0 address after deployment
      token1, // Token1 address after deployment
    ],
    { after: [token0, token1] }
  ); // Ensure token0 and token1 are deployed first

  // Deploy the Strategy Contract
  const strategycontract = m.contract("StrategyContract");

  // Deploy the Staking Contract (depends on UniswapV2Pair and StrategyContract)
  const stakingcontract = m.contract(
    "StakingContract",
    [
      uniswapv2pair, // Ensure UniswapV2Pair is deployed first
    ],
    { after: [uniswapv2pair] }
  ); // Ensure UniswapV2Pair and StrategyContract are deployed first

  // Deploy the ERC4626 Vault contract with the StakingContract address
  const vault = m.contract(
    "ERC4626",
    [
      stakingcontract, // Ensure StakingContract is deployed first
    ],
    { after: [stakingcontract] }
  ); // Ensure StakingContract is deployed first

  // Call the initialize function of StrategyContract after all contracts are deployed
  const initializeTx = m.call(
    strategycontract,
    "initialize",
    [
      uniswapv2pair, // UniswapV2Pair address
      stakingcontract, // StakingContract address
      vault, // Vault contract address
    ],
    { after: [vault, stakingcontract, uniswapv2pair, strategycontract] }
  ); // Ensure vault, stakingcontract, and uniswapv2pair are deployed first

  // Return the deployed contracts
  return {
    token0,
    token1,
    uniswapv2pair,
    strategycontract,
    stakingcontract,
    // vault,
  };
});
