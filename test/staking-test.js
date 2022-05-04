const { parseEther } = require("ethers/lib/utils");
const { ethers, deployments } = require("hardhat");
const { moveBlocks } = require("../utils/move-blocks");
const { moveTime } = require("../utils/move-time");

const SECOND_IN_DAY = 86400;

describe("Staking", async function () {
  let stakingContract, rewardToken, deployer, stakeAmount;

  beforeEach(async function () {
    const accounts = await ethers.getSigners();
    deployer = accounts[0];
    await deployments.fixture(["all"]);
    stakingContract = await ethers.getContract("Staking");
    rewardToken = await ethers.getContract("RewardToken");
    stakeAmount = ethers.utils.parseEther("100000");
  });

  it("allows user to stake and claim rewards", async function () {
    await rewardToken.approve(stakingContract.address, stakeAmount);
    await stakingContract.stake(stakeAmount);
    const startingEarned = await stakingContract.earned(deployer.address);
    console.log(`Starting Earned: ${startingEarned}`);

    await moveTime(SECOND_IN_DAY);
    await moveBlocks(1)

    const endingEarned = await stakingContract.earned(deployer.address);
    console.log(`Ending Earned: ${endingEarned}`);
  });
});
