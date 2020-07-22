pragma solidity ^0.6.4;

import "../drip/PeriodicShare.sol";

contract PeriodicShareExposed {
  using PeriodicShare for PeriodicShare.State;

  PeriodicShare.State referrals;

  function initialize(uint256 _periodSeconds, uint256 _currentTime) external {
    referrals.initialize(_periodSeconds, _currentTime);
  }

  function isPeriodOver(uint256 currentTime) external view returns (bool) {
    return referrals.isPeriodOver(currentTime);
  }

  function completePeriod(uint256 totalAccrued, uint256 currentTime) external {
    referrals.completePeriod(totalAccrued, currentTime);
  }

  function mint(address user, uint256 amount) external {
    referrals.mint(user, amount);
  }
}
