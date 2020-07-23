pragma solidity ^0.6.4;

import "../drip/VolumeDrip.sol";

contract VolumeDripExposed {
  using VolumeDrip for VolumeDrip.State;

  VolumeDrip.State referrals;

  function initialize(uint256 _periodSeconds, uint256 _currentTime) external {
    referrals.initialize(_periodSeconds, _currentTime);
  }

  function isPeriodOver(uint256 currentTime) external view returns (bool) {
    return referrals.isPeriodOver(currentTime);
  }

  function completePeriod(uint256 currentTime) external {
    referrals.completePeriod(currentTime);
  }

  function mint(address user, uint256 amount) external {
    referrals.mint(user, amount);
  }
}
