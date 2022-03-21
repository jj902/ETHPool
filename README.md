# ETHPool

## Description

ETHPool provides a service where people can deposit ETH and they will receive weekly rewards.
Users must be able to take out their deposits along with their portion of rewards at any time.
New rewards are deposited manually into the pool by the ETHPool team each week using a contract function.

Example:

> Let say we have user **A** and **B** and team **T**.
>
> **A** deposits 100, and **B** deposits 300 for a total of 400 in the pool. Now **A** has 25% of the pool and **B** has 75%. When **T** deposits 200 rewards, **A** should be able to withdraw 150 and **B** 450.
>
> What if the following happens? **A** deposits then **T** deposits then **B** deposits then **A** withdraws and finally **B** withdraws.
> **A** should get their deposit + all the rewards.
> **B** should only get their deposit because rewards were sent to the pool before they participated.

## How To

Compile: `yarn compile`

Testing: `yarn test`

Deploy: `yarn deploy`

## Interaction(Hardhat Tasks)

Get Total ETH balance held in the contract: 

`npx hardhat eth-amount --ethpool 0x0ABf2526F7822840b4c645c5525048D833a7658a --network kovan`

Get Details of signed user:

`npx hardhat accounts --ethpool 0x0ABf2526F7822840b4c645c5525048D833a7658a --network kovan`

## Smart Contract Address

https://kovan.etherscan.io/address/0x0ABf2526F7822840b4c645c5525048D833a7658a
