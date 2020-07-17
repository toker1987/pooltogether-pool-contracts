pragma solidity ^0.6.4;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol";
import "@pooltogether/fixed-point/contracts/FixedPoint.sol";
import "@nomiclabs/buidler/console.sol";

library Drip {
  using SafeMath for uint256;
  using SafeCast for uint256;

  struct UserState {
    uint128 lastExchangeRateMantissa;
    uint128 dripBalance;
  }

  struct State {
    uint256 dripRatePerBlock;
    uint256 drippedTotalSupply;
    mapping(address => UserState) userStates;
    uint128 exchangeRateMantissa;
    uint32 blockNumber;
  }

  function initialize(State storage self, uint256 currentBlockNumber) internal {
    self.exchangeRateMantissa = FixedPoint.SCALE.toUint128();
    self.blockNumber = currentBlockNumber.toUint32();
  }

  function updateExchangeRate(State storage self, uint256 measureTotalSupply, uint256 currentBlockNumber) internal {
    // this should only run once per block.
    if (self.blockNumber == uint32(currentBlockNumber)) {
      return;
    }

    uint256 newBlocks = currentBlockNumber.sub(self.blockNumber);
    uint256 newTokens = newBlocks.mul(self.dripRatePerBlock);
    uint256 indexDeltaMantissa = FixedPoint.calculateMantissa(newTokens, measureTotalSupply);

    if (indexDeltaMantissa > 0) {
      self.exchangeRateMantissa = uint256(self.exchangeRateMantissa).add(indexDeltaMantissa).toUint128();
      self.blockNumber = currentBlockNumber.toUint32();
    }
  }

  function drip(
    State storage self,
    address user,
    uint256 userMeasureBalance,
    uint256 measureTotalSupply,
    uint256 availableDripTokenSupply,
    uint256 currentBlockNumber
  ) internal returns (uint256) {
    updateExchangeRate(self, measureTotalSupply, currentBlockNumber);
    UserState storage userState = self.userStates[user];
    uint256 lastExchangeRateMantissa = userState.lastExchangeRateMantissa;
    if (lastExchangeRateMantissa == 0) {
      // if the index is not intialized
      lastExchangeRateMantissa = self.exchangeRateMantissa;
    }

    // How many tokens we held previously
    uint256 oldTokens = FixedPoint.multiplyUintByMantissa(userMeasureBalance, lastExchangeRateMantissa);

    // How many tokens should we now hold?
    uint256 currentTokens = FixedPoint.multiplyUintByMantissa(userMeasureBalance, self.exchangeRateMantissa);

    // calculate the difference
    uint256 newTokens = currentTokens > oldTokens ? currentTokens.sub(oldTokens) : 0;

    if (newTokens > availableDripTokenSupply) {
      newTokens = availableDripTokenSupply;
    }

    self.userStates[user] = UserState({
      lastExchangeRateMantissa: self.exchangeRateMantissa,
      dripBalance: uint256(userState.dripBalance).add(newTokens).toUint128()
    });

    return newTokens;
  }

  function burnDrip(
    State storage self,
    address user,
    uint256 amount
  ) internal {
    UserState storage userState = self.userStates[user];
    userState.dripBalance = uint256(userState.dripBalance).sub(amount).toUint128();
  }
}
