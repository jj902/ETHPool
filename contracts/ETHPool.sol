// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *  @author Jeremy Jin
 *  @title ETHPool
 *  @notice ETHPool provides a service where people can deposit ETH and they will receive rewards.
 */
contract ETHPool is Ownable {
    using SafeMath for uint256;

    /**
     *  @notice Staked Balance of user
     */
    mapping(address => uint256) public stakedBalances;

    /**
     *  @notice Total amount of staked balance of all users.
     */
    uint256 public totalStakedBalance;

    /**
     *  @dev Reverted Reward amount for a user.
     *      Real reward is subtraction of this revertedRewards from the reward that just summarized.
     */
    mapping(address => uint256) private _revertedRewards;

    /**
     *  @dev Total Reward Rate is the sum of all the rate of rewards
     *      Each rate is rewarding amount divides total staked balance.
     */
    uint256 private _totalRewardRate;

    /**
     *  @notice This emits when user deposit(stake) some amount of ETH.
     *  @param _from The address of user who wants to stake.
     *  @param _amount The staking amount.
     */
    event Deposit(address payable indexed _from, uint256 _amount);

    /**
     *  @notice This emits when team(owner) deposits reward.
     *  @dev It throws when totalStakedBalance is zero.
     *  @param _amount The reward amount.
     */
    event Reward(uint256 _amount);

    /**
     *  @notice This emits when user withdraws all staked balance and rewards.
     *  @dev It throws when staked balance of user is zero.
     *  @param _to The address of user who wants to withdraw.
     *  @param _stakedAmount Total staked amount so far for this user.
     *  @param _rewardAmount Total reward amount so far for this user.
     */
    event Withdraw(
        address indexed _to,
        uint256 _stakedAmount,
        uint256 _rewardAmount
    );

    /**
     *  @notice Function for user to deposit(stake) some amount of ETH
     *  @dev we calculate stakedBalances, totalStakedBalance and _revertedRewards here.
     *      Calculating _revertedRewards is main focus here:
     *      _revertedRewards[msg.sender] += _totalRewardRate * msg.value
     */
    function deposit() external payable {
        stakedBalances[msg.sender] += msg.value;
        totalStakedBalance += msg.value;

        uint256 _lastRevertedReward = _totalRewardRate.mul(msg.value);
        _revertedRewards[msg.sender] = _revertedRewards[msg.sender].add(
            _lastRevertedReward
        );

        emit Deposit(payable(msg.sender), msg.value);
    }

    /**
     *  @notice Function for the team to deposit reward.
     *  @dev we calculate _totalRewardRate here:
     *      _totalRewardRate += msg.value / totalStakedBalance
     *  @dev Throws when totalStakedBalance is zero
     */
    function reward() external payable onlyOwner {
        require(totalStakedBalance > 0, "No one has deposited yet");

        uint256 _lastRewardRate = msg.value.div(totalStakedBalance);
        _totalRewardRate = _totalRewardRate.add(_lastRewardRate);

        emit Reward(msg.value);
    }

    /**
     *  @notice Function for user to deposit all his/her staked balance and reward.
     *  @dev Here, we calculate real reward, calculate total withdrawl amount,
     *      and then send that amount to user's address.
     *      Calculating real reward is main focus here:
     *      _realReward = _stakedBalance * _totalRewardRate - revertedRewards[msg.sender]
     *  @dev Throws when staked Balance is zero, or if withdraw fails.
     */
    function withdraw() external {
        require(
            stakedBalances[msg.sender] > 0,
            "You have no balance to withdraw"
        );

        uint256 _stakedBalance = stakedBalances[msg.sender];
        uint256 _rewardForStaked = _stakedBalance.mul(_totalRewardRate);
        uint256 _realReward = _rewardForStaked.sub(
            _revertedRewards[msg.sender]
        );
        uint256 _totalWitdraw = _stakedBalance.add(_realReward);

        stakedBalances[msg.sender] = 0;
        _revertedRewards[msg.sender] = 0;
        totalStakedBalance = totalStakedBalance.sub(_stakedBalance);

        (bool success, ) = payable(msg.sender).call{value: _totalWitdraw}("");
        require(success, "Could not withdraw");

        emit Withdraw(msg.sender, _stakedBalance, _realReward);
    }
}