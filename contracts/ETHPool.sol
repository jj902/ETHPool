// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ETHPool is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public stakedBalances;
    uint256 public totalStakedBalance;

    mapping(address => uint256) private _revertedRewards;
    uint256 private _rewardProportion;

    event Deposit(address payable indexed from, uint256 amount);
    event Reward(uint256 amount);
    event Withdraw(
        address indexed to,
        uint256 stakedAmount,
        uint256 rewardAmount
    );

    function deposit() external payable {
        stakedBalances[msg.sender] += msg.value;
        totalStakedBalance += msg.value;

        uint256 _lastRevertedReward = _rewardProportion.mul(msg.value);
        _revertedRewards[msg.sender] = _revertedRewards[msg.sender].add(
            _lastRevertedReward
        );

        emit Deposit(payable(msg.sender), msg.value);
    }

    function reward() external payable onlyOwner {
        require(totalStakedBalance > 0, "No one has deposited yet");

        uint256 _lastRewardProportion = msg.value.div(totalStakedBalance);
        _rewardProportion = _rewardProportion.add(_lastRewardProportion);

        emit Reward(msg.value);
    }

    function withdraw() external {
        require(
            stakedBalances[msg.sender] > 0,
            "You have no balance to withdraw"
        );

        uint256 _stakedBalance = stakedBalances[msg.sender];
        uint256 _rewardForStaked = _stakedBalance.mul(_rewardProportion);
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
