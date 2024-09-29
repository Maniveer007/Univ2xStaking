const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("StrategyContract", function () {
  async function deployContracts() {
    const [owner, user1, user2, user3] = await ethers.getSigners();

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
    const stakingcontract = await StakingContract.deploy(uniswapv2pair.target);

    const Vault = await ethers.getContractFactory("ERC4626");
    const vault = await Vault.deploy(stakingcontract.target);

    const tx = await strategycontract.initialize(
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

      // console.log(await strategycontract.getUserRewards(user1.address));

      await vault
        .connect(user1)
        .approve(strategycontract_user1.target, vaultshares);
      await strategycontract_user1.withdraw(vaultshares);

      expect(await token0.balanceOf(user1.address)).to.be.gt(0);
      expect(await token1.balanceOf(user1.address)).to.be.gt(0);
    });

    it("Should revert if withdraw amount exceeds balance of vault", async function () {
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

    it("Should revert if withdraw amount exceeds balance of user", async function () {
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

    it("withdraw with an specific amount", async function () {
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
      await strategycontract_user1.withdraw(100);

      expect(await token0.balanceOf(user1.address)).to.be.gt(0);
      expect(await token1.balanceOf(user1.address)).to.be.gt(0);
    });

    it("withdraw with claimRewards function ", async function () {
      const {
        token0,
        token1,
        strategycontract,
        vault,
        minttoken0,
        minttoken1,
        user1,
        user2,
      } = await loadFixture(deployContracts);

      await minttoken0(user1.address, 10000);
      await minttoken1(user1.address, 10000);

      await token0.connect(user1).approve(strategycontract.target, 10000);
      await token1.connect(user1).approve(strategycontract.target, 10000);

      const strategycontract_user1 = await strategycontract.connect(user1);
      await strategycontract_user1.deposit(10000, 10000);

      await minttoken0(user2.address, 10000);
      await minttoken1(user2.address, 10000);

      await token0.connect(user2).approve(strategycontract.target, 10000);
      await token1.connect(user2).approve(strategycontract.target, 10000);

      const strategycontract_user2 = await strategycontract.connect(user2);
      await strategycontract_user2.deposit(10000, 10000);

      const vaultshares = await vault.balanceOf(user1.address);
      expect(vaultshares).to.be.gt(0);

      await vault
        .connect(user1)
        .approve(strategycontract_user1.target, vaultshares);
      // console.log(await strategycontract.getUserRewards(user1.address));

      await strategycontract_user1.claimRewards();

      expect(await token0.balanceOf(user1.address)).to.be.gt(0);
      expect(await token1.balanceOf(user1.address)).to.be.gt(0);
    });

    describe("StakingContract", function () {
      it("Should deposit tokens correctly", async function () {
        const {
          token0,
          token1,
          stakingcontract,
          strategycontract,
          minttoken0,
          minttoken1,
          user1,
        } = await loadFixture(deployContracts);

        await minttoken0(user1.address, 10000);
        await minttoken1(user1.address, 10000);

        await token0.connect(user1).approve(strategycontract.target, 10000);
        await token1.connect(user1).approve(strategycontract.target, 10000);

        await strategycontract.connect(user1).deposit(10000, 10000);

        // expect(await stakingcontract.balanceOf(user1.address)).to.equal(10000);
      });

      it("user receive more reward according to their stake", async function () {
        const {
          token0,
          token1,
          stakingcontract,
          strategycontract,
          uniswapv2pair,
          minttoken0,
          minttoken1,
          user1,
          user2,
          user3,
        } = await loadFixture(deployContracts);

        await minttoken0(user1.address, 10000);
        await minttoken1(user1.address, 10000);

        await token0.connect(user1).approve(strategycontract.target, 10000);
        await token1.connect(user1).approve(strategycontract.target, 10000);

        await strategycontract.connect(user1).deposit(10000, 10000);

        const user1balances_before = await strategycontract.getUserRewards(
          user1.address
        );

        await minttoken0(user2.address, 10000);
        await minttoken1(user2.address, 10000);

        await token0.connect(user2).approve(strategycontract.target, 10000);
        await token1.connect(user2).approve(strategycontract.target, 10000);

        await strategycontract.connect(user2).deposit(10000, 10000);

        const user2balances_before = await strategycontract.getUserRewards(
          user2.address
        );

        await minttoken0(user3.address, 10000);
        await minttoken1(user3.address, 10000);

        await token0.connect(user3).transfer(uniswapv2pair.target, 10000);
        await token1.connect(user3).transfer(uniswapv2pair.target, 10000);

        await uniswapv2pair.connect(user3).mint(user3.address);

        const uniswapbalanceofuser3 = await uniswapv2pair.balanceOf(
          user3.address
        );

        // console.log(uniswapbalanceofuser3);

        await uniswapv2pair
          .connect(user3)
          .transfer(stakingcontract.target, uniswapbalanceofuser3);

        const user1balances_after = await strategycontract.getUserRewards(
          user1.address
        );
        const user2balances_after = await strategycontract.getUserRewards(
          user2.address
        );

        expect(user1balances_after[2]).to.be.gt(user1balances_before[2]);
        expect(user2balances_after[2]).to.be.gt(user2balances_before[2]);

        expect(user1balances_after[0]).to.be.gt(user1balances_before[0]);
        expect(user2balances_after[0]).to.be.gt(user2balances_before[0]);

        expect(user1balances_after[1]).to.be.gt(user1balances_before[1]);
        expect(user2balances_after[1]).to.be.gt(user2balances_before[1]);
      });
    });
    describe("strategy contract", function () {
      it("cannot deposit if not initalized ", async function () {
        const { token0, token1, user1 } = await loadFixture(deployContracts);

        const StrategyContract = await ethers.getContractFactory(
          "StrategyContract"
        );
        const strategycontract = await StrategyContract.deploy();

        await token0.connect(user1).approve(strategycontract.target, 10000);
        await token1.connect(user1).approve(strategycontract.target, 10000);

        const strategycontract_user1 = await strategycontract.connect(user1);
        await expect(strategycontract_user1.deposit(10000, 10000)).to.be
          .reverted;
      });

      it("cannot withdraw if not initalized ", async function () {
        const { token0, token1, user1 } = await loadFixture(deployContracts);

        const StrategyContract = await ethers.getContractFactory(
          "StrategyContract"
        );
        const strategycontract = await StrategyContract.deploy();

        await token0.connect(user1).approve(strategycontract.target, 10000);
        await token1.connect(user1).approve(strategycontract.target, 10000);

        const strategycontract_user1 = await strategycontract.connect(user1);
        await expect(strategycontract_user1.withdraw(10000)).to.be.reverted;
      });
    });
  });
});
