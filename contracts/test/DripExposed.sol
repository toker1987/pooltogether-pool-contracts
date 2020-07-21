pragma solidity ^0.6.4;

import "../drip/Drip.sol";

contract DripExposed {
  using Drip for Drip.State;

  Drip.State internal dripState;

  function initialize(
    uint256 dripRatePerBlock,
    uint256 currentBlockNumber
  ) external {
    dripState.initialize(currentBlockNumber);
    dripState.dripRatePerBlock = dripRatePerBlock;
  }

  function drip(
    address user,
    uint256 userMeasureBalance,
    uint256 measureTotalSupply,
    uint256 currentBlockNumber
  ) external {
    dripState.drip(
      user,
      userMeasureBalance,
      measureTotalSupply,
      currentBlockNumber
    );
  }

  function burnDrip(
    address user,
    uint256 amount
  ) external {
    dripState.burnDrip(user, amount);
  }

  function balanceOf(address user) external view returns (uint256) {
    return dripState.userStates[user].dripBalance;
  }

  function exchangeRateMantissa() external view returns (uint256) {
    return dripState.exchangeRateMantissa;
  }
}