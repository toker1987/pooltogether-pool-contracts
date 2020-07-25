pragma solidity ^0.6.4;

import "@nomiclabs/buidler/console.sol";

import "../drip/BalanceDripManager.sol";

contract BalanceDripManagerExposed {
  using BalanceDripManager for BalanceDripManager.State;

  BalanceDripManager.State dripManager;

  function updateDrips(
    address measure,
    address user,
    uint256 measureBalance,
    uint256 measureTotalSupply,
    uint256 blockNumber
  ) external {
    dripManager.updateDrips(measure, user, measureBalance, measureTotalSupply, blockNumber);
  }

  function addDrip(address measure, address dripToken, uint256 dripRatePerBlock, uint256 blockNumber) external {
    dripManager.addDrip(measure, dripToken, dripRatePerBlock, blockNumber);
  }

  function hasDrip(address measure, address dripToken) external view returns (bool) {
    return dripManager.hasDrip(measure, dripToken);
  }

  function setDripRate(address measure, address dripToken, uint256 dripRatePerBlock) external {
    dripManager.setDripRate(measure, dripToken, dripRatePerBlock);
  }

  function balanceOfDrip(address user, address measure, address dripToken) external view returns (uint256) {
    return dripManager.balanceOfDrip(user, measure, dripToken);
  }

  function getDrip(
    address measure,
    address dripToken
  )
    external
    view
    returns (
      uint256 dripRatePerBlock,
      uint128 exchangeRateMantissa,
      uint32 blockNumber
    )
  {
    BalanceDrip.State storage dripState = dripManager.getDrip(measure, dripToken);
    dripRatePerBlock = dripState.dripRatePerBlock;
    exchangeRateMantissa = dripState.exchangeRateMantissa;
    blockNumber = dripState.blockNumber;
  }

  function claimDripTokens(address user, address measure, address dripToken) external {
    dripManager.claimDripTokens(user, measure, dripToken);
  }
}
