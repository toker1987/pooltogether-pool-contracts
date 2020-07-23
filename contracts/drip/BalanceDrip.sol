pragma solidity ^0.6.4;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol";
import "@pooltogether/fixed-point/contracts/FixedPoint.sol";
import "@nomiclabs/buidler/console.sol";

library BalanceDrip {
  using SafeMath for uint256;
  using SafeCast for uint256;

  struct UserState {
    uint128 lastExchangeRateMantissa;
    uint128 dripBalance;
  }

  struct State {
    uint256 dripRatePerBlock;
    uint128 exchangeRateMantissa;
    uint32 blockNumber;
    mapping(address => UserState) userStates;
  }

  function initialize(State storage self, uint256 currentBlock) internal {
    self.exchangeRateMantissa = FixedPoint.SCALE.toUint128();
    self.blockNumber = currentBlock.toUint32();
  }

  function updateExchangeRate(
    State storage self,
    uint256 measureTotalSupply,
    uint256 currentBlock
  ) internal {
    // this should only run once per block.
    if (self.blockNumber == uint32(currentBlock)) {
      return;
    }

    uint256 newBlocks = currentBlock.sub(self.blockNumber);

    if (newBlocks > 0 && self.dripRatePerBlock > 0) {
      uint256 newTokens = newBlocks.mul(self.dripRatePerBlock);
      uint256 indexDeltaMantissa = measureTotalSupply > 0 ? FixedPoint.calculateMantissa(newTokens, measureTotalSupply) : 0;
      self.exchangeRateMantissa = uint256(self.exchangeRateMantissa).add(indexDeltaMantissa).toUint128();
      self.blockNumber = currentBlock.toUint32();
    } else {
      self.blockNumber = currentBlock.toUint32();
    }
  }

  function drip(
    State storage self,
    address user,
    uint256 userMeasureBalance,
    uint256 measureTotalSupply,
    uint256 currentBlock
  ) internal returns (uint256) {
    updateExchangeRate(self, measureTotalSupply, currentBlock);
    return dripUser(
      self,
      user,
      userMeasureBalance
    );
  }

  function dripUser(
    State storage self,
    address user,
    uint256 userMeasureBalance
  ) internal returns (uint256) {
    UserState storage userState = self.userStates[user];
    uint256 lastExchangeRateMantissa = userState.lastExchangeRateMantissa;
    if (lastExchangeRateMantissa == 0) {
      // if the index is not intialized
      lastExchangeRateMantissa = self.exchangeRateMantissa;
    }

    uint256 deltaExchangeRateMantissa = uint256(self.exchangeRateMantissa).sub(lastExchangeRateMantissa);
    uint256 newTokens = FixedPoint.multiplyUintByMantissa(userMeasureBalance, deltaExchangeRateMantissa);
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
