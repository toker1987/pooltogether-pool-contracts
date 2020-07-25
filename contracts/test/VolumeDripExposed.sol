pragma solidity ^0.6.4;

import "../drip/VolumeDrip.sol";

contract VolumeDripExposed {
  using VolumeDrip for VolumeDrip.State;

  event DripTokensBurned(address user, uint256 amount);

  VolumeDrip.State state;

  function initialize(uint32 periodBlocks, uint128 dripRatePerBlock, uint32 currentBlock) external {
    state.initialize(periodBlocks, dripRatePerBlock, currentBlock);
  }

  function isPeriodOver(uint256 currentTime) external view returns (bool) {
    return state.isPeriodOver(currentTime);
  }

  function completePeriod(uint256 currentTime) external {
    state.completePeriod(currentTime);
  }

  function mint(address user, uint256 amount, uint256 currentBlock) external {
    state.mint(user, amount, currentBlock);
  }

  function burnDrip(address user, uint256 currentBlock) external {
    uint256 amount = state.burnDrip(user, currentBlock);
    emit DripTokensBurned(user, amount);
  }

  function getDrip()
    external
    view
    returns (
      uint32 periodBlocks,
      uint32 periodStartedAt,
      uint128 dripRatePerBlock
    )
  {
    periodBlocks = state.periodBlocks;
    periodStartedAt = state.periodStartedAt;
    dripRatePerBlock = state.dripRatePerBlock;
  }

  function getPeriod(uint256 periodIndex)
    external
    view
    returns (
      uint128 totalSupply,
      uint128 totalAccrued
    )
  {
    totalSupply = state.periods[periodIndex].totalSupply;
    totalAccrued = state.periods[periodIndex].totalAccrued;
  }

  function getDeposit(address user)
    external
    view
    returns (
      uint128 balance,
      uint16 period,
      uint112 accrued
    )
  {
    balance = state.deposits[user].balance;
    period = state.deposits[user].period;
    accrued = state.deposits[user].accrued;
  }

}
