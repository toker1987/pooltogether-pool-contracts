pragma solidity ^0.6.4;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol";
import "@pooltogether/fixed-point/contracts/FixedPoint.sol";

library PeriodicShare {
  using SafeMath for uint256;
  using SafeCast for uint256;

  struct Deposit {
    uint128 balance;
    uint128 period;
    uint256 accrued;
  }

  struct Period {
    uint128 totalSupply;
    uint128 totalAccrued;
  }

  struct State {
    mapping(address => Deposit) deposits;
    Period[] periods;
    uint128 periodBlocks;
    uint128 periodStartedAt;
    uint256 dripRatePerBlock;
  }

  function initialize(State storage self, uint256 _periodBlocks, uint256 _currentBlock) internal {
    require(_periodBlocks > 0, "PeriodicShare/period-gt-zero");
    Period memory empty = Period({
      totalSupply: 0,
      totalAccrued: 0
    });
    self.periods.push(empty); // keep an empty period as magic number
    self.periods.push(empty); // this is the actual "first" period
    self.periodBlocks = _periodBlocks.toUint128();
    self.periodStartedAt = _currentBlock.toUint128();
  }

  function isPeriodOver(State storage self, uint256 currentBlock) internal view returns (bool) {
    return currentBlock > uint256(self.periodStartedAt).add(self.periodBlocks);
  }

  function completePeriod(State storage self, uint256 currentBlock) internal onlyPeriodOver(self, currentBlock) {
    uint256 periodTokens;
    Period storage period = self.periods[_currentPeriodIndex(self)];
    // if referrals were made
    if (period.totalSupply > 0) {
      // reward the users
      uint256 newBlocks = currentBlock.sub(self.periodStartedAt);
      periodTokens = newBlocks.mul(self.dripRatePerBlock);
      self.periods[_currentPeriodIndex(self)].totalAccrued = periodTokens.toUint128();
    }
    Period memory empty = Period({
      totalSupply: 0,
      totalAccrued: 0
    });
    self.periods.push(empty);
    self.periodStartedAt = currentBlock.toUint128();
  }

  function mint(State storage self, address user, uint256 amount) internal {
    uint256 lastPeriod = self.deposits[user].period;
    // first let's check to see if the previous period has completed
    if (lastPeriod < _currentPeriodIndex(self)) {
      // claim their past period
      uint256 fractionMantissa = FixedPoint.calculateMantissa(self.deposits[user].balance, self.periods[lastPeriod].totalSupply);
      uint256 accrued = FixedPoint.multiplyUintByMantissa(self.periods[lastPeriod].totalAccrued, fractionMantissa);
      self.deposits[user] = Deposit({
        balance: amount.toUint128(),
        period: _currentPeriodIndex(self),
        accrued: self.deposits[user].accrued.add(accrued)
      });
    } else {
      self.deposits[user].balance = uint256(self.deposits[user].balance).add(amount).toUint128();
      self.deposits[user].period = _currentPeriodIndex(self);
    }
  }

  function _currentPeriodIndex(State storage self) internal view returns (uint128) {
    return self.periods.length.sub(1).toUint128();
  }

  modifier onlyPeriodOver(State storage self, uint256 _currentBlock) {
    require(_currentBlock > self.periodStartedAt.add(self.periodBlocks), "PeriodicShare/period-not-over");
    _;
  }
}
