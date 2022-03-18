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
     *  @dev We use BASE to make calculation of fixed point numbers to be calculation of integer.
     */
    uint256 private constant BASE = 10**18;

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
     *  @param _totalAmount Total amount so far for this user.
     */
    event Withdraw(
        address indexed _to,
        uint256 _stakedAmount,
        uint256 _rewardAmount,
        uint256 _totalAmount
    );

    /**
     *  @notice Function for user to deposit(stake) some amount of ETH
     *  @dev we calculate stakedBalances, totalStakedBalance and _revertedRewards here.
     *      Calculating _revertedRewards is main focus here:
     *      _revertedRewards[msg.sender] += _totalRewardRate * msg.value
     */
    function deposit() external payable {
        stakedBalances[msg.sender] = stakedBalances[msg.sender].add(msg.value);
        totalStakedBalance = totalStakedBalance.add(msg.value);

        uint256 _lastRevertedReward = _totalRewardRate.mul(msg.value).div(BASE);
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

        uint256 _lastRewardRate = msg.value.mul(BASE).div(totalStakedBalance);
        _totalRewardRate = _totalRewardRate.add(_lastRewardRate);

        emit Reward(msg.value);
    }

    /**
     *  @notice Function for user to withdraw all his/her staked balance and reward.
     *  @dev Here, we calculate real reward, calculate total withdrawl amount,
     *      Clears staked Balance and reverted Reward for that user,
     *      and then transfer that amount to user's address.
     *  @dev Throws when staked Balance is zero, or if withdraw fails.
     */
    function withdraw() external {
        uint256 _realReward = getRewardAmount(msg.sender);
        uint256 _stakedBalance = stakedBalances[msg.sender];
        uint256 _withdrawlAmount = _stakedBalance.add(_realReward);

        stakedBalances[msg.sender] = 0;
        _revertedRewards[msg.sender] = 0;
        totalStakedBalance = totalStakedBalance.sub(_stakedBalance);

        (bool success, ) = payable(msg.sender).call{value: _withdrawlAmount}(
            ""
        );
        require(success, "Could not withdraw");

        emit Withdraw(
            msg.sender,
            _stakedBalance,
            _realReward,
            _withdrawlAmount
        );
    }

    /**
     *  @notice Function to get Real Reward for user.
     *  @dev Here, we get the real reward like this:
     *      _realReward = _stakedBalance * _totalRewardRate - _revertedRewards[staker]
     *  @dev Throws when staked Balance is zero.
     *  @param _staker Address of user(Staker)
     *  @return _realReward Real Reward that staker can get so far.
     */
    function getRewardAmount(address _staker)
        public
        view
        returns (uint256 _realReward)
    {
        require(stakedBalances[_staker] > 0, "You have no balance to withdraw");

        uint256 _rewardForStaked = stakedBalances[_staker]
            .mul(_totalRewardRate)
            .div(BASE);
        _realReward = _rewardForStaked.sub(_revertedRewards[_staker]);
    }
}
