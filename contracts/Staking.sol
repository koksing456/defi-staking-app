// stake - people puts token into the contract ✅
// unstake - people unlocks tokens from the contract ✅
// claim reward - people get rewards after staking their tokens
// what's some good reward mechanism?
// what's some good reward math?

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedMoreThanZero();

contract Staking {
  uint256 public constant REWARD_RATE = 100;
  uint256 public s_totalSupply;
  uint256 public s_rewardPerTokenStored;
  uint256 public s_lastUpdateTime;

  IERC20 public s_stakingToken;
  IERC20 public s_rewardToken;

  //someone address -> how much they have staked
  mapping(address => uint256) public s_balances;
  // a mapping of how much rewards each address has to claim
  mapping(address => uint256) public s_rewards;
  // a mapping of how much rewards each address has been paid
  mapping(address => uint256) public s_userRewardPerTokenPaid;

  modifier updateReward(address _account) {
    // what is the reward per token store
    // 1 reward token when staked = 100
    // 0.5 reward token when staked = 200
    s_rewardPerTokenStored = rewardPerToken();
    s_lastUpdateTime = block.timestamp;
    s_rewards[_account] = earned(_account);
    s_userRewardPerTokenPaid[_account] = s_rewardPerTokenStored;
    _;
  }

  modifier moreThanZero(uint256 _amount) {
    if (_amount == 0) revert Staking__NeedMoreThanZero();
    _;
  }

  constructor(address _stakingToken, address _rewardToken) {
    s_stakingToken = IERC20(_stakingToken);
    s_rewardToken = IERC20(_rewardToken);
  }

  //based on how long it's been during most recent snapshot
  function rewardPerToken() private view returns (uint256) {
    if (s_totalSupply == 0) return s_rewardPerTokenStored;

    return
      s_rewardPerTokenStored +
      (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) /
        s_totalSupply);
  }

  function earned(address _account) public view returns (uint256) {
    uint256 currentBalance = s_balances[_account];

    //how much they have been paid already
    uint256 amountPaid = s_userRewardPerTokenPaid[_account];
    uint256 currentRewardPerToken = rewardPerToken();
    uint256 pastReward = s_rewards[_account];

    return
      ((currentBalance * (currentRewardPerToken - amountPaid)) / 1e18) +
      pastReward;
  }

  // do we allow any tokens? - only one token in this moment (need chainlink stuff to convert prices between tokens)
  // or just specific token? ✅
  function stake(uint256 _amount)
    external
    updateReward(msg.sender)
    moreThanZero(_amount)
  {
    // keep track of how much this user has staked
    s_balances[msg.sender] = s_balances[msg.sender] + _amount;

    // keep track of how much this token we have total
    s_totalSupply = s_totalSupply + _amount;

    //emit event

    // transfer token to this contract
    bool success = s_stakingToken.transferFrom(
      msg.sender,
      address(this),
      _amount
    );
    // require(success, "transfer tokens from user to contract is failed");
    if (!success) {
      revert Staking__TransferFailed();
    }
  }

  function unStake(uint256 _amount)
    external
    updateReward(msg.sender)
    moreThanZero(_amount)
  {
    // keep track of how much this user has staked
    s_balances[msg.sender] = s_balances[msg.sender] - _amount;

    // keep track of how much this token we have total
    s_totalSupply = s_totalSupply - _amount;

    //emit event

    // transfer token to this contract
    bool success = s_stakingToken.transfer(msg.sender, _amount);
    // require(success, "transfer tokens from user to contract is failed");
    if (!success) {
      revert Staking__TransferFailed();
    }
  }

  function claimReward() external updateReward(msg.sender) {
    // how much reward will they get?
    // the contract will emit x tokens per second
    // and disperse them to all token stakers
    //
    // emit 100 tokens per second
    // staked: 50, 20, 30
    // rewards: 50, 20, 30
    //
    // staked: 100, 50, 20, 30 (total = 200)
    // reward: 50, 25, 10, 15 because emit 100 person and shared by 200, so rate = 100/200 = 0.5

    uint256 rewards = s_rewards[msg.sender];

    bool success = s_rewardToken.transfer(msg.sender, rewards);
    if (!success) {
      revert Staking__TransferFailed();
    }
  }
}
