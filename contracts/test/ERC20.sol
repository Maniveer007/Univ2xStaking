// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

/*
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("StrategyContract", function () {
  async function deployContracts() {
    const [owner, user1, user2, user3] = await ethers.getSigners();
    const INTREST_RATE = 10;

    const Token0 = await ethers.getContractFactory("MyToken");
    const token0 = await Token0.deploy(owner.address);

    const Token1 = await ethers.getContractFactory("MyToken");
    const token1 = await Token1.deploy(owner.address);

    const UniswapV2Pair = await ethers.getContractFactory("UniswapV2Pair");
    const uniswapv2pair = await UniswapV2Pair.deploy(
      token0.target,
      token1.target
    );

    const StrategyContract = await ethers.getContractFactory(
      "StrategyContract"
    );
    const strategycontract = await StrategyContract.deploy();

    const StakingContract = await ethers.getContractFactory("StakingContract");
    const stakingcontract = await StakingContract.deploy(
      uniswapv2pair.target,
      strategycontract.target
    );

    const Vault = await ethers.getContractFactory("ERC4626");
    const vault = await Vault.deploy(stakingcontract.target);

    const tx = await strategycontract.initalize(
      stakingcontract.target,
      uniswapv2pair.target,
      stakingcontract.target,
      vault.target
    );
    await tx.wait();

    const minttoken0 = async (user, amount) => {
      const tx = await token0.mint(user, amount);
      await tx.wait();
    };

    const minttoken1 = async (user, amount) => {
      const tx = await token1.mint(user, amount);
      await tx.wait();
    };

    return {
      token0,
      token1,
      uniswapv2pair,
      stakingcontract,
      vault,
      strategycontract,
      minttoken0,
      minttoken1,
      owner,
      user1,
      user2,
      user3,
    };
  }

  describe("tokens", function () {
    it("Should deploy contracts and initialize correctly", async function () {
      const { token0, token1, stakingcontract, owner } = await loadFixture(
        deployContracts
      );

      expect(await token0.owner()).to.equal(owner.address);
      expect(await token1.owner()).to.equal(owner.address);
    });

    it("Should mint tokens correctly", async function () {
      const { token0, token1, minttoken0, minttoken1, user1 } =
        await loadFixture(deployContracts);

      await minttoken0(user1.address, 10000);
      await minttoken1(user1.address, 10000);

      expect(await token0.balanceOf(user1.address)).to.equal(10000);
      expect(await token1.balanceOf(user1.address)).to.equal(10000);
    });

    it("Should revert if deposit amount exceeds balance", async function () {
      const {
        token0,
        token1,
        strategycontract,
        minttoken0,
        minttoken1,
        user1,
      } = await loadFixture(deployContracts);

      await minttoken0(user1.address, 5000);
      await minttoken1(user1.address, 5000);

      await token0.connect(user1).approve(strategycontract.target, 10000);
      await token1.connect(user1).approve(strategycontract.target, 10000);

      const strategycontract_user1 = await strategycontract.connect(user1);
      await expect(strategycontract_user1.deposit(10000, 10000)).to.be.reverted;
    });
  });
  describe("deposits and withdrawals", function () {
    it("Should handle deposits and withdrawals correctly", async function () {
      const {
        token0,
        token1,
        strategycontract,
        vault,
        minttoken0,
        minttoken1,
        user1,
      } = await loadFixture(deployContracts);

      await minttoken0(user1.address, 10000);
      await minttoken1(user1.address, 10000);

      await token0.connect(user1).approve(strategycontract.target, 10000);
      await token1.connect(user1).approve(strategycontract.target, 10000);

      const strategycontract_user1 = await strategycontract.connect(user1);
      await strategycontract_user1.deposit(10000, 10000);

      const vaultshares = await vault.balanceOf(user1.address);
      expect(vaultshares).to.be.gt(0);

      await vault
        .connect(user1)
        .approve(strategycontract_user1.target, vaultshares);
      await strategycontract_user1.withdraw(vaultshares);

      expect(await token0.balanceOf(user1.address)).to.be.gt(0);
      expect(await token1.balanceOf(user1.address)).to.be.gt(0);
    });

    it("Should revert if withdraw amount exceeds balance", async function () {
      const {
        token0,
        token1,
        strategycontract,
        vault,
        minttoken0,
        minttoken1,
        user1,
      } = await loadFixture(deployContracts);

      await minttoken0(user1.address, 10000);
      await minttoken1(user1.address, 10000);

      await token0.connect(user1).approve(strategycontract.target, 10000);
      await token1.connect(user1).approve(strategycontract.target, 10000);

      const strategycontract_user1 = await strategycontract.connect(user1);
      await strategycontract_user1.deposit(10000, 10000);

      const vaultshares = await vault.balanceOf(user1.address);
      expect(vaultshares).to.be.gt(0);

      await vault
        .connect(user1)
        .approve(strategycontract_user1.target, vaultshares);

      await expect(strategycontract_user1.withdraw(Number(vaultshares) + 1)).to
        .be.reverted;
    });
    it("Should revert if withdraw amount exceeds balance", async function () {
      const {
        token0,
        token1,
        strategycontract,
        vault,
        minttoken0,
        minttoken1,
        user1,
      } = await loadFixture(deployContracts);

      await minttoken0(user1.address, 10000);
      await minttoken1(user1.address, 10000);

      await token0.connect(user1).approve(strategycontract.target, 10000);
      await token1.connect(user1).approve(strategycontract.target, 10000);

      const strategycontract_user1 = await strategycontract.connect(user1);
      await strategycontract_user1.deposit(10000, 10000);

      const vaultshares = await vault.balanceOf(user1.address);
      expect(vaultshares).to.be.gt(0);

      await vault.connect(user1).transfer(strategycontract.target, 100);

      await expect(strategycontract_user1.withdraw(vaultshares)).to.be.reverted;
    });
    it("should revert if deposit is lessthan MINIMUM_DEPOSIT", async function () {
      const {
        token0,
        token1,
        strategycontract,
        vault,
        minttoken0,
        minttoken1,
        user1,
      } = await loadFixture(deployContracts);

      await minttoken0(user1.address, 10000);
      await minttoken1(user1.address, 10000);

      await token0.connect(user1).approve(strategycontract.target, 10000);
      await token1.connect(user1).approve(strategycontract.target, 10000);

      const strategycontract_user1 = await strategycontract.connect(user1);
      await expect(strategycontract_user1.deposit(10, 10)).to.be.reverted;
    });
  });

  it("testing if staked amount is increased");
});

/*

it("Should handle deposits and withdrawals correctly", async function () {
      const {
        token0,
        token1,
        strategycontract,
        vault,
        minttoken0,
        minttoken1,
        user1,
      } = await loadFixture(deployContracts);

      await minttoken0(user1.address, 10000);
      await minttoken1(user1.address, 10000);

      await token0.connect(user1).approve(strategycontract.target, 10000);
      await token1.connect(user1).approve(strategycontract.target, 10000);

      const strategycontract_user1 = await strategycontract.connect(user1);
      await strategycontract_user1.deposit(10000, 10000);

      const vaultshares = await vault.balanceOf(user1.address);
      expect(vaultshares).to.be.gt(0);

      await vault
        .connect(user1)
        .approve(strategycontract_user1.target, vaultshares);
      await strategycontract_user1.withdraw(vaultshares);

      expect(await token0.balanceOf(user1.address)).to.be.gt(0);
      expect(await token1.balanceOf(user1.address)).to.be.gt(0);
    });

*/

