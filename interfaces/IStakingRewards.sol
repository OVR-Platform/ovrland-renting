// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;

interface IStakingRewards {
  function availableBalance(address _address)
    external
    view
    returns (uint256 _balance);

  function withdraw(
    address _addressFrom,
    address _addressTo,
    uint256 _amount
  ) external;

  function deposit(address _address, uint256 _amount) external;
}
