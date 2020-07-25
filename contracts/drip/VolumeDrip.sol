pragma solidity ^0.6.4;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol";
import "@pooltogether/fixed-point/contracts/FixedPoint.sol";
import "@nomiclabs/buidler/console.sol";

import "../utils/ExtendedSafeCast.sol";

library VolumeDrip {
  using SafeMath for uint256;
  using SafeCast for uint256;
  using ExtendedSafeCast for uint256;

  struct Deposit {
    uint128 balance;
    uint16 period;
    uint112 accrued;
  }

  struct Period {
    uint128 totalSupply;
    uint128 totalAccrued;
  }

  struct State {
    mapping(address => Deposit) deposits;
    Period[] periods;
    uint32 periodBlocks;
    uint32 periodStartedAt;
    uint128 dripRatePerBlock;
  }

  function initialize(State storage self, uint32 _periodBlocks, uint128 dripRatePerBlock, uint32 _currentBlock) internal {
    require(_periodBlocks > 0, "VolumeDrip/period-gt-zero");
    Period memory empty = Period({
      totalSupply: 0,
      totalAccrued: 0
    });
    self.periods.push(empty); // keep an empty period as magic number
    self.periods.push(empty); // this is the actual "first" period
    self.periodBlocks = _periodBlocks;
    self.periodStartedAt = _currentBlock;
    self.dripRatePerBlock = dripRatePerBlock;
  }

  function isPeriodOver(State storage self, uint256 currentBlock) internal view returns (bool) {
    return currentBlock >= uint256(self.periodStartedAt).add(self.periodBlocks);
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
    self.periodStartedAt = currentBlock.toUint32();
  }

  function nextUserState(State storage self, address user, uint256 currentBlock) internal returns (Deposit memory) {
    if (isPeriodOver(self, currentBlock)) {
      // console.log("period over! %s", currentBlock);
      completePeriod(self, currentBlock);
    }
    Deposit memory deposit = self.deposits[user];
    uint256 lastPeriod = deposit.period;
    // console.log("lastPeriod: %s", lastPeriod);
    // first let's check to see if the previous period has completed
    if (lastPeriod == 0) {
      // console.log("is zero, setting to %s", _currentPeriodIndex(self));
      deposit = Deposit({
        balance: 0,
        period: _currentPeriodIndex(self),
        accrued: 0
      });
    } else if (lastPeriod < _currentPeriodIndex(self)) {
      // claim their past period
      uint256 fractionMantissa = FixedPoint.calculateMantissa(self.deposits[user].balance, self.periods[lastPeriod].totalSupply);
      uint256 accrued = FixedPoint.multiplyUintByMantissa(self.periods[lastPeriod].totalAccrued, fractionMantissa);
      // console.log("claiming %s", accrued);
      deposit = Deposit({
        balance: 0,
        period: _currentPeriodIndex(self),
        accrued: uint256(self.deposits[user].accrued).add(accrued).toUint112()
      });
    }

    return deposit;
  }

  function mint(State storage self, address user, uint256 amount, uint256 currentBlock) internal {
    Deposit memory deposit = nextUserState(self, user, currentBlock);
    // console.log("balance: %s", deposit.balance);
    // console.log("period: %s", deposit.period);
    deposit.balance = uint256(deposit.balance).add(amount).toUint128();
    Period storage period = self.periods[_currentPeriodIndex(self)];
    period.totalSupply = uint256(period.totalSupply).add(amount).toUint128();
    self.deposits[user] = deposit;
    // console.log("updated period: %s", self.deposits[user].period);
  }

  function burnDrip(State storage self, address user, uint256 currentBlock) internal returns (uint256 accrued) {
    Deposit memory deposit = nextUserState(self, user, currentBlock);
    accrued = deposit.accrued;

    deposit.accrued = 0;
    self.deposits[user] = deposit;
  }

  function _currentPeriodIndex(State storage self) internal view returns (uint16) {
    return self.periods.length.sub(1).toUint16();
  }

  modifier onlyPeriodOver(State storage self, uint256 _currentBlock) {
    require(isPeriodOver(self, _currentBlock), "VolumeDrip/period-not-over");
    _;
  }
}
