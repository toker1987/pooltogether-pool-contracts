pragma solidity ^0.6.4;

import "@nomiclabs/buidler/console.sol";

import "../drip/DripManager.sol";

contract DripManagerExposed {
  using DripManager for DripManager.State;

  DripManager.State dripManager;

  function updateDrips(address measure, address user, uint256 blockNumber) external {
    dripManager.updateDrips(measure, user, blockNumber);
  }

  function addDripToken(address measure, address dripToken, uint256 dripRatePerBlock, uint256 blockNumber) external {
    dripManager.addDripToken(measure, dripToken, dripRatePerBlock, blockNumber);
  }

  function hasDripToken(address measure, address dripToken) external view returns (bool) {
    return dripManager.hasDripToken(measure, dripToken);
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
    Drip.State storage dripState = dripManager.getDrip(measure, dripToken);
    dripRatePerBlock = dripState.dripRatePerBlock;
    exchangeRateMantissa = dripState.exchangeRateMantissa;
    blockNumber = dripState.blockNumber;
  }

  function claimDrip(address user, address measure, address dripToken) external {
    dripManager.claimDrip(user, measure, dripToken);
  }
}
