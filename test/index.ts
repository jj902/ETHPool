import { expect } from "chai";
import { ethers } from "hardhat";
import { ETHPool } from "typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("ETHPool contract", function () {
  let ETHPool;
  let ethPool: ETHPool;
  let team: SignerWithAddress;
  let userA: SignerWithAddress;
  let userB: SignerWithAddress;

  beforeEach(async function () {
    ETHPool = await ethers.getContractFactory("ETHPool");
    [team, userA, userB] = await ethers.getSigners();

    ethPool = await ETHPool.deploy();
  });

  describe("Deployment", function () {
    it("Should set the right team", async function () {
      expect(await ethPool.owner()).to.equal(team.address);
    });
  });

  describe("Deposits", function () {
    it("Anyone can deposit", async function () {
      await expect(
        ethPool
          .connect(userA)
          .deposit({ value: ethers.utils.parseEther("0.1") })
      )
        .to.emit(ethPool, "Deposit")
        .withArgs(userA.address, ethers.utils.parseEther("0.1"));
      const userAStakedBalance = await ethPool.stakedBalances(userA.address);
      expect(userAStakedBalance).to.equal(ethers.utils.parseEther("0.1"));
    });
  });

  describe("Reward", function () {
    it("Only team can reward", async function () {
      await expect(
        ethPool.connect(userA).reward({ value: ethers.utils.parseEther("0.1") })
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Shouldn't able to reward if no one deposited yet", async function () {
      await expect(
        ethPool.connect(team).reward({ value: ethers.utils.parseEther("0.1") })
      ).to.be.revertedWith("No one has deposited yet");
    });

    it("Team can reward if someone deposited already", async function () {
      await expect(
        ethPool
          .connect(userA)
          .deposit({ value: ethers.utils.parseEther("0.1") })
      )
        .to.emit(ethPool, "Deposit")
        .withArgs(userA.address, ethers.utils.parseEther("0.1"));
      await expect(
        ethPool.connect(team).reward({ value: ethers.utils.parseEther("0.1") })
      )
        .to.emit(ethPool, "Reward")
        .withArgs(ethers.utils.parseEther("0.1"));
    });
  });

  describe("Withdraw", function () {
    it("Nothing to withdrawl", async function () {
      await expect(ethPool.connect(userA).withdraw()).to.be.revertedWith(
        "You have no balance to withdraw"
      );
    });

    it("If user has depositied, he can withdraw", async function () {
      await expect(
        ethPool
          .connect(userA)
          .deposit({ value: ethers.utils.parseEther("0.1") })
      )
        .to.emit(ethPool, "Deposit")
        .withArgs(userA.address, ethers.utils.parseEther("0.1"));

      await expect(ethPool.connect(userA).withdraw())
        .to.emit(ethPool, "Withdraw")
        .withArgs(
          userA.address,
          ethers.utils.parseEther("0.1"),
          0,
          ethers.utils.parseEther("0.1")
        );
    });
  });

  describe("E2E Tests", function () {
    /* 
      userA deposits 100, and userB deposits 300 for a total of 400 in the pool. 
      Now userA has 25% of the pool and userB has 75%. When Team deposits 200 rewards, userA should be able to withdraw 150 and userB 450.
    */
    it("Case 1: userA and userB invests, no one is late.", async function () {
      await ethPool.connect(userA).deposit({ value: 100 });
      await ethPool.connect(userB).deposit({ value: 300 });
      await ethPool.connect(team).reward({ value: 200 });

      await expect(ethPool.connect(userA).withdraw())
        .to.emit(ethPool, "Withdraw")
        .withArgs(userA.address, 100, 50, 150); // 100 staked, 50 reward, 150 in total
      await expect(ethPool.connect(userB).withdraw())
        .to.emit(ethPool, "Withdraw")
        .withArgs(userB.address, 300, 150, 450); // 300 staked, 150 reward, 450 in total
    });

    /* 
      userA deposits 100, then Team deposits 200 rewards, then userB deposits 300. 
      userA should get their deposit + all the rewards. userB should only get their deposit because rewards were sent to the pool before they participated.
    */
    it("Case 2: userA and userB invests, userB is late.", async function () {
      await ethPool.connect(userA).deposit({ value: 100 });
      await ethPool.connect(team).reward({ value: 200 });
      await ethPool.connect(userB).deposit({ value: 300 });

      await expect(ethPool.connect(userA).withdraw())
        .to.emit(ethPool, "Withdraw")
        .withArgs(userA.address, 100, 200, 300); // 100 staked, 200 reward, 300 in total
      await expect(ethPool.connect(userB).withdraw())
        .to.emit(ethPool, "Withdraw")
        .withArgs(userB.address, 300, 0, 300); // 300 staked, 0 reward, 300 in total
    });

    it("Case 3: Complex", async function () {
      await ethPool.connect(userA).deposit({ value: 100 });
      await ethPool.connect(team).reward({ value: 200 });
      await ethPool.connect(userA).deposit({ value: 100 });
      await ethPool.connect(userB).deposit({ value: 300 });
      await ethPool.connect(team).reward({ value: 500 });
      await ethPool.connect(userB).deposit({ value: 300 });

      await expect(ethPool.connect(userA).withdraw())
        .to.emit(ethPool, "Withdraw")
        .withArgs(userA.address, 200, 400, 600); // 200 staked, 400 rewards, 600 in total
      await expect(ethPool.connect(userB).withdraw())
        .to.emit(ethPool, "Withdraw")
        .withArgs(userB.address, 600, 300, 900); // 600 staked, 300 rewards, 900 in total
    });
  });
});
